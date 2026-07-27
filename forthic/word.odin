package forthic

Native_Word_Proc :: proc(interp: ^Interpreter) -> Error

// This is what happens when a Forthic word is executed
Word_Action :: union {
  Native_Word_Proc,
  Forthic_Value,
  // TODO: Add definition word execution
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
  }
  return nil
}

