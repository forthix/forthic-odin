package forthic

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

// 0-indexed. Out-of-range is nil, matching the permissive style of
// JQ@/log.LINE rather than erroring.
builtin_nth :: proc(interp: ^Interpreter) -> Error {
  n_value, n_err := stack_pop(&interp.stack)
  if n_err != nil {
    return n_err
  }
  container_value, container_err := stack_pop(&interp.stack)
  if container_err != nil {
    return container_err
  }

  n, is_int := n_value.(i64)
  arr, is_array := container_value.([dynamic]Forthic_Value)
  if !is_int || !is_array {
    return Type_Mismatch{note = "NTH requires (container:array n:int)"}
  }

  item: Forthic_Value
  if n >= 0 && int(n) < len(arr) {
    item = arr[n]
  }

  stack_push(&interp.stack, item)
  return nil
}
