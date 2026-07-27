package forthic

Native_Word_Proc :: proc(interp: ^Interpreter) -> Error

// This is what happens when a Forthic word is executed
Word_Action :: union {
  Native_Word_Proc,
  Forthic_Value,
  [dynamic]Compiled_Word,
}

Compiled_Word :: struct {
  name: string,
  action: Word_Action
}

compiled_word_execute :: proc(interp: ^Interpreter, word: Compiled_Word) -> Error {
  switch action in word.action {
  case Native_Word_Proc:
    return action(interp)
  case Forthic_Value:
    stack_push(&interp.stack, action)
    return nil
  case [dynamic]Compiled_Word:
    for w in action {
      w_err := compiled_word_execute(interp, w)
      if w_err != nil {
        // TODO: Should we clean anything up here?
        return w_err
      }
    }
  }
  return nil
}

