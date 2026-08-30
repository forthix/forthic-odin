package forthic

// ( options:record -- )
builtin_set_options :: proc(interp: ^Interpreter) -> Error {
  record, err := stack_pop_record(&interp.stack, "options should be a record")
  if err != nil {
    return err
  }

  interp.pending_word_options = Word_Options(record)
  return nil
}
