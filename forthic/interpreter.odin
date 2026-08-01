package forthic

import "core:strings"
import "core:strconv"
import "core:mem"
import "core:mem/virtual"
import "core:os"

Interpreter :: struct {
  // Parameter stack
  stack:  Stack,

  // Tokenizer stack (needed for when we do things like MAP or RUN
  tokenizer_stack: [dynamic]Tokenizer,

  registered_modules: map[string]^Module,

  // Modules can be opened up from other modules at runtime. This captures that nesting
  module_stack: [dynamic]^Module,

  // Array/record support
  collection_start_positions: [dynamic]Collection_Start,

  literal_handlers: [dynamic]Literal_Handler,

  pending_word_options: Maybe(Word_Options),

  // Compile support
  is_compiling: bool,
  cur_definition_name: string,
  cur_definition_body: [dynamic]Compiled_Word,
  pending_doc_lines: [dynamic]string,
  pending_word_doc: Maybe(Word_Doc),

  // Memory management
  word_arena: virtual.Arena,
  default_allocator: mem.Allocator,
}

interpreter_arena_allocator :: proc(interp: ^Interpreter) -> mem.Allocator {
  return virtual.arena_allocator(&interp.word_arena)
}

interpreter_init :: proc(interp: ^Interpreter) {
  // Pin the stack to the normal (non-arena) allocator *before* switching
  // context.allocator below -- a [dynamic]T locks in whichever allocator
  // is active the first time it actually allocates, and every later
  // append/delete on it keeps using that same one regardless of what
  // context.allocator becomes afterward.
  interp.stack.items = make([dynamic]Forthic_Value, 0)
  interp.default_allocator = context.allocator

  _ = virtual.arena_init_growing(&interp.word_arena)
  context.allocator = interpreter_arena_allocator(interp)

  app_module := module_create("")
  module_import_words(app_module, core_module_create()) 

  append(&interp.module_stack, app_module)

  // Specify literal handlers
  append(&interp.literal_handlers, literal_to_bool)
  append(&interp.literal_handlers, literal_to_float)
  append(&interp.literal_handlers, literal_to_int)

}

interpreter_destroy :: proc(interp: ^Interpreter) {
  stack_destroy(&interp.stack)
  delete(interp.tokenizer_stack)
  delete(interp.module_stack)
  virtual.arena_destroy(&interp.word_arena)
}

interpreter_register_module :: proc(interp: ^Interpreter, module: ^Module) {
  interp.registered_modules[module.name] = module
}

interpreter_register_and_import_module :: proc(interp: ^Interpreter, module: ^Module, prefix: string) {
  interpreter_register_module(interp, module)
  app_module := interp.module_stack[0]
  module_import_words_prefixed(app_module, module, prefix)
}


interpreter_run_file :: proc(interp: ^Interpreter, filename: string) -> Error {
  contents, read_err := os.read_entire_file(filename, context.allocator)
  if read_err != nil {
    return Read_File_Error{path = filename, err = read_err}
  }
  defer delete(contents)

  positioned_forthic := Positioned_Forthic{string(contents), nil}
  return interpreter_run(interp, positioned_forthic)
}

interpreter_run :: proc(interp: ^Interpreter, positioned_forthic: Positioned_Forthic) -> Error {
  context.allocator = interpreter_arena_allocator(interp)

  tokenizer :  Tokenizer
  tokenizer_init(&tokenizer, positioned_forthic)
  append(&interp.tokenizer_stack, tokenizer)
  defer tokenizer_destroy(&tokenizer)

  // Run the Forthic
  for {
    cur_tokenizer := &interp.tokenizer_stack[len(interp.tokenizer_stack) - 1]
    token, err := tokenizer_next_token(cur_tokenizer)
    if err != nil {
      return err
    }
    if token.token_type == .Eos {
      if interp.is_compiling {
        return Missing_Semicolon{location = token.location}
      }
      break
    }

    handle_err := interpreter_handle_token(interp, token)
    delete(token.text)
    if handle_err != nil {
      return handle_err
    }
  }

  pop(&interp.tokenizer_stack)
  return nil
}

interpreter_handle_token :: proc(interp: ^Interpreter, token: Token) -> Error {
  // Clear out pending doc lines if not a comment or start definition
  if token.token_type != .Comment && token.token_type != .StartDef && len(interp.pending_doc_lines) > 0 {
    clear(&interp.pending_doc_lines)
  }

  // Handle each token
  #partial switch token.token_type {
  case .Word:
    return interpreter_handle_word_token(interp, token)
  case .Comment:
    return interpreter_handle_comment_token(interp, token)
  case .StartDef:
    if interp.is_compiling {
      return Missing_Semicolon{location = token.location}
    }
    interp.is_compiling = true
    interp.cur_definition_name = strings.clone(token.text)
    interp.cur_definition_body = make([dynamic]Compiled_Word, 0)
    if len(interp.pending_doc_lines) > 0 {
      interp.pending_word_doc = interpreter_parse_pending_doc(interp)
      clear(&interp.pending_doc_lines)
    }
    return nil
  case .EndDef:
    if !interp.is_compiling {
      return Extra_Semicolon{location = token.location}
    }
    new_word := Compiled_Word{
      name = interp.cur_definition_name,
      action = interp.cur_definition_body,
      doc = interp.pending_word_doc,
    }
    top_module := interp.module_stack[len(interp.module_stack) - 1]
    module_add_word(top_module, new_word)
    interp.is_compiling = false
    interp.pending_word_doc = nil
    return nil
  case .DotSymbol:
    new_value : Dot_Symbol = Dot_Symbol(strings.clone(token.text))
    return interpreter_handle_word(interp, Compiled_Word{name = strings.clone("<dot-symbol>"), action = Forthic_Value(new_value)})
  case .String:
    return interpreter_handle_word(interp, Compiled_Word{name = strings.clone("<string>"), action = Forthic_Value(strings.clone(token.text))})
  case .StartArray:
    return interpreter_handle_word(interp, Compiled_Word{name = strings.clone("["), action = Native_Word_Proc(native_start_array)})
  case .EndArray:
    return interpreter_handle_word(interp, Compiled_Word{name = strings.clone("]"), action = Native_Word_Proc(native_end_array)})
  case .StartRecord:
    return interpreter_handle_word(interp, Compiled_Word{name = strings.clone("{"), action = Native_Word_Proc(native_start_record)})
  case .EndRecord:
    return interpreter_handle_word(interp, Compiled_Word{name = strings.clone("}"), action = Native_Word_Proc(native_end_record)})
  case:
     return nil
  }
}

interpreter_handle_word_token :: proc(interp: ^Interpreter, token: Token) -> Error {
  word, found := interpreter_find_word(interp, token.text)
  if found {
    return interpreter_handle_word(interp, word)
  }

  // Check literals
  for literal_handler in interp.literal_handlers {
    value, ok := literal_handler(token.text)
    if ok {
      return interpreter_handle_word(interp, Compiled_Word{name = strings.clone(token.text), action = value})
    }
  }

  return Unknown_Word{word = strings.clone(token.text, interp.default_allocator), location = token.location}
}


interpreter_handle_word :: proc(interp: ^Interpreter, word: Compiled_Word) -> Error {
  if interp.is_compiling {
    append(&interp.cur_definition_body, word)
    return nil
  }
  return compiled_word_execute(interp, word)
}

interpreter_handle_comment_token :: proc(interp: ^Interpreter, token: Token) -> Error {
  if strings.has_prefix(token.text, "#:") {
    line := strings.trim_left_space(strings.trim_prefix(token.text, "#:"))
    append(&interp.pending_doc_lines, strings.clone(line))
  }
  else {
    clear(&interp.pending_doc_lines)
  }
  return nil
}


interpreter_find_word :: proc(interp: ^Interpreter, name: string) -> (Compiled_Word, bool) {
 #reverse for m in interp.module_stack {
   word, ok := module_find_word(m, name)
   if ok {
     return word, true
   }
 }
 return {}, false
}

interpreter_parse_pending_doc :: proc(interp: ^Interpreter) -> Word_Doc {
  stack_effect: string
  examples: [dynamic]string
  description_lines: [dynamic]string

  for line in interp.pending_doc_lines {
    if strings.has_prefix(line, "@effect") {
      stack_effect = strings.trim_left_space(strings.trim_prefix(line, "@effect"))
    }
    else if strings.has_prefix(line, "@example") {
      append(&examples, strings.trim_left_space(strings.trim_prefix(line, "@example")))
    }
    else {
      append(&description_lines, line)
    }
  }

  return Word_Doc{
    stack_effect = stack_effect,
    description = strings.join(description_lines[:], " "),
    examples = examples[:],
  }
}
