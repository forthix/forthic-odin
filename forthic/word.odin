package forthic

Native_Word_Proc :: proc(interp: ^Interpreter) -> Error

// This is what happens when a Forthic word is executed
Word_Action :: union {
  Native_Word_Proc,
  Forthic_Value,
  [dynamic]Compiled_Word,
}


Word_Doc :: struct {
  stack_effect: string,
  description: string,
  examples: []string,
}

Compiled_Word :: struct {
  name: string,
  action: Word_Action,
  doc: Maybe(Word_Doc),
}

compiled_word_execute :: proc(interp: ^Interpreter, word: Compiled_Word) -> Error {
  switch action in word.action {
  case Native_Word_Proc:
    err := action(interp)
    if word.name != "~>" {
      interp.pending_word_options = nil
    }
    return err
  case Forthic_Value:
    stack_push(&interp.stack, action)
    interp.pending_word_options = nil
    return nil
  case [dynamic]Compiled_Word:
    for w in action {
      w_err := compiled_word_execute(interp, w)
      if w_err != nil {
        return w_err
      }
    }
    interp.pending_word_options = nil
  }
  return nil
}

