package forthic

// ( container -- length:int )
builtin_length :: proc(interp: ^Interpreter) -> Error {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  n: i64
  #partial switch v in value {
  case [dynamic]Forthic_Value:
    n = i64(len(v))
  case Record:
    n = i64(len(v))
  case:
    return Type_Mismatch{note = "LENGTH requires an array or record"}
  }

  stack_push(&interp.stack, Forthic_Value(n))
  return nil
}

// ( container:array n:int -- item )
// 0-indexed. Out-of-range is nil, matching the permissive style of
// JQ@/log.LINE rather than erroring.
builtin_nth :: proc(interp: ^Interpreter) -> Error {
  n, n_err := pop_int(interp, "NTH")
  if n_err != nil {
    return n_err
  }
  arr, arr_err := pop_array(interp, "NTH")
  if arr_err != nil {
    return arr_err
  }

  item: Forthic_Value
  if n >= 0 && int(n) < len(arr) {
    item = arr[n]
  }

  stack_push(&interp.stack, item)
  return nil
}

// Reads the with_key option (bool) from a preceding { .with_key TRUE } ~>.
// Defaults to false if unset.
map_with_key_option :: proc(interp: ^Interpreter) -> bool {
  options, has_options := interp.pending_word_options.?
  if !has_options {
    return false
  }
  value, ok := Record(options)[Dot_Symbol("with_key")]
  if !ok {
    return false
  }
  b, is_bool := value.(bool)
  return is_bool && b
}

// ( items:array forthic:string -- mapped:array )
// Runs forthic once per item, collecting each run's single resulting value
// into mapped, in order. With { .with_key TRUE } ~> set beforehand, pushes
// each item's 0-based index before the item itself.
builtin_map :: proc(interp: ^Interpreter) -> Error {
  source, source_err := pop_string(interp, "MAP")
  if source_err != nil {
    return source_err
  }
  items, items_err := pop_array(interp, "MAP")
  if items_err != nil {
    return items_err
  }

  with_key := map_with_key_option(interp)

  results := make([dynamic]Forthic_Value, 0, len(items))
  for item, i in items {
    if with_key {
      stack_push(&interp.stack, Forthic_Value(i64(i)))
    }
    stack_push(&interp.stack, item)
    run_err := interpreter_run(interp, Positioned_Forthic{source, nil})
    if run_err != nil {
      return run_err
    }
    result, pop_err := stack_pop(&interp.stack)
    if pop_err != nil {
      return pop_err
    }
    append(&results, result)
  }

  stack_push(&interp.stack, Forthic_Value(results))
  return nil
}

// ( items:array forthic:string -- ? )
// Runs forthic once per item, for side effects -- no per-item result is
// collected (see MAP for that). With { .with_key TRUE } ~> set beforehand,
// pushes each item's 0-based index before the item itself.
builtin_foreach :: proc(interp: ^Interpreter) -> Error {
  source, source_err := pop_string(interp, "FOREACH")
  if source_err != nil {
    return source_err
  }
  items, items_err := pop_array(interp, "FOREACH")
  if items_err != nil {
    return items_err
  }

  with_key := map_with_key_option(interp)

  for item, i in items {
    if with_key {
      stack_push(&interp.stack, Forthic_Value(i64(i)))
    }
    stack_push(&interp.stack, item)
    run_err := interpreter_run(interp, Positioned_Forthic{source, nil})
    if run_err != nil {
      return run_err
    }
  }
  return nil
}
