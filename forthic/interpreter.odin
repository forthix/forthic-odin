package forthic

import "core:strings"
import "core:strconv"
import "core:mem"
import "core:mem/virtual"

Interpreter :: struct {
  // Parameter stack
  stack:  Stack,

  // Tokenizer stack (needed for when we do things like MAP or RUN
  tokenizer_stack: [dynamic]Tokenizer,

  // Modules can be opened up from other modules at runtime. This captures that nesting
  module_stack: [dynamic]^Module,

  // Compile support
  is_compiling: bool,
  cur_definition_name: string,
  cur_definition_body: [dynamic]Compiled_Word,

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
  append(&app_module.words, Compiled_Word{
    name = strings.clone("+"),
    action = Native_Word_Proc(native_plus),
  })

  append(&interp.module_stack, app_module)
}

interpreter_destroy :: proc(interp: ^Interpreter) {
  stack_destroy(&interp.stack)
  delete(interp.tokenizer_stack)
  delete(interp.module_stack)
  virtual.arena_destroy(&interp.word_arena)
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
  #partial switch token.token_type {
  case .Word:
    return interpreter_handle_word_token(interp, token)
  case .StartDef:
    interp.is_compiling = true
    interp.cur_definition_name = strings.clone(token.text)
    interp.cur_definition_body = make([dynamic]Compiled_Word, 0)
    return nil
  case .EndDef:
    new_word := Compiled_Word{
      name = interp.cur_definition_name,
      action = interp.cur_definition_body,
    }
    top_module := interp.module_stack[len(interp.module_stack) - 1]
    append(&top_module.words, new_word)
    interp.is_compiling = false
    return nil
  case:
     return nil
  }
}

interpreter_handle_word_token :: proc(interp: ^Interpreter, token: Token) -> Error {
  word, found := interpreter_find_word(interp, token.text)
  if found {
    return interpreter_handle_word(interp, word)
  }

  // TODO: Add literal handlers
  int_val, ok := strconv.parse_i64(token.text)
  if ok {
    return interpreter_handle_word(interp, Compiled_Word{name = strings.clone("<int>"), action = Forthic_Value(int_val)})
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


interpreter_find_word :: proc(interp: ^Interpreter, name: string) -> (Compiled_Word, bool) {
 #reverse for m in interp.module_stack {
   word, ok := module_find_word(m, name)
   if ok {
     return word, true
   }
 }
 return {}, false
}
