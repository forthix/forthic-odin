package forthic

import "core:strings"
import "core:strconv"

Interpreter :: struct {
    stack:  Stack,
    tokenizer_stack: [dynamic]Tokenizer,
    module_stack: [dynamic]^Module,
}

interpreter_init :: proc(interp: ^Interpreter) {
  app_module := new(Module)
  app_module.name = ""

  append(&app_module.words, Compiled_Word{
    name = "+",
    action = Native_Word_Proc(native_plus)
  })

  append(&interp.module_stack, app_module)
}

interpreter_destroy :: proc(interp: ^Interpreter) {
  stack_destroy(&interp.stack)
  delete(interp.tokenizer_stack)
  for m in interp.module_stack {
    module_destroy(m)
  }
  delete(interp.module_stack)
}


interpreter_run :: proc(interp: ^Interpreter, positioned_forthic: Positioned_Forthic) -> Error {
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
  case:
     return nil
  }
}

interpreter_handle_word_token :: proc(interp: ^Interpreter, token: Token) -> Error {
  word, found := interpreter_find_word(interp, token.text)
  if found {
    return compiled_word_execute(interp, word)
  }

  // TODO: Add literal handlers
  int_val, ok := strconv.parse_i64(token.text)
  if ok {
    stack_push(&interp.stack, Forthic_Value(int_val))
    return nil
  }

  return Unknown_Word{word = strings.clone(token.text), location = token.location}
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
