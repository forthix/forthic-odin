package forthic

builtin_set_options :: proc(interp: ^Interpreter) -> Error {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  record, is_record := value.(Record)
  if !is_record {
    return Type_Mismatch{ note = "options should be a record", location = Code_Location{} }
  }

  interp.pending_word_options = Word_Options(record)
  return nil
}
