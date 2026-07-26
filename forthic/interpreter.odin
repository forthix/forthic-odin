package forthic


Interpreter :: struct {
    stack:  [dynamic]Forthic_Value,
    tokenizer_stack: [dynamic]Tokenizer
}

interpreter_init :: proc(interp: ^Interpreter) {

}

interpreter_destroy :: proc(interp: ^Interpreter) {
  delete(interp.stack)
  delete(interp.tokenizer_stack)
}


interpreter_run :: proc(interp: ^Interpreter, positioned_forthic: Positioned_Forthic) -> string {
  tokenizer :  Tokenizer
  tokenizer_init(&tokenizer, positioned_forthic)
  append(&interp.tokenizer_stack, tokenizer)
  defer tokenizer_destroy(&tokenizer)

  // TODO: Run the Forthic

  pop(&interp.tokenizer_stack)
  return positioned_forthic.forthic
}

