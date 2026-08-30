package log_forthic

import "../../forthic"

// Full session history, never truncated. Rendering a bounded window (e.g.
// "last 5 lines") is a Forthic-side decision made with log.COUNT/log.LINE,
// not something baked in here. Entries are opaque Forthic_Values -- a plain
// string, or a record like { .turn n .text "..." } if the caller wants
// structured fields to render separately.
messages: [dynamic]forthic.Forthic_Value

log_module_create :: proc() -> ^forthic.Module {
  log_module := forthic.module_create("log")

  forthic.module_add_builtin_word(
    log_module, "APPEND", builtin_log_append, "( entry -- )",
    "Appends an entry (any value -- a string, or a record for structured fields) to the session log. Never drops old entries.",
    {`{ .turn 5 .text "You can't go that way." } log.APPEND`},
  )
  forthic.module_add_builtin_word(
    log_module, "COUNT", builtin_log_count, "( -- n:int )",
    "Number of entries in the log so far.",
    {"log.COUNT"},
  )
  forthic.module_add_builtin_word(
    log_module, "LINE", builtin_log_line, "( index:int -- entry )",
    "Gets an entry by index (0 = oldest). Out-of-range returns nil.",
    {"0 log.LINE"},
  )
  forthic.module_add_builtin_word(
    log_module, "CLEAR", builtin_log_clear, "( -- )",
    "Removes all entries. Used when rebuilding the log from replayed history.",
    {"log.CLEAR"},
  )

  return log_module
}

builtin_log_append :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  value, err := forthic.stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  append(&messages, value)
  return nil
}

builtin_log_count :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  forthic.stack_push(&interp.stack, forthic.Forthic_Value(i64(len(messages))))
  return nil
}

builtin_log_clear :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  clear(&messages)
  return nil
}

builtin_log_line :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  value, err := forthic.stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  index, is_int := value.(i64)
  if !is_int {
    return forthic.Type_Mismatch{note = "log.LINE requires an int index"}
  }

  entry: forthic.Forthic_Value
  if index >= 0 && int(index) < len(messages) {
    entry = messages[index]
  }

  forthic.stack_push(&interp.stack, entry)
  return nil
}
