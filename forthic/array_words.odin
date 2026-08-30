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
