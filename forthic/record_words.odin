package forthic

// Drills into a container by a path of record fields (Dot_Symbol or string)
// and/or array indices (int). A bare (non-array) path is treated as a single
// segment, so a single dot-symbol works directly: `.player-facing @ JQ@`.
// Permissive like forthic-ts's JQ@: any miss along the way yields nil rather
// than an error. Unlike forthic-ts, jq-style path *strings* (".users[].name")
// aren't parsed here -- only the path-array form is supported, which is all
// this codebase currently needs.
builtin_jq_at :: proc(interp: ^Interpreter) -> Error {
  path, path_err := stack_pop(&interp.stack)
  if path_err != nil {
    return path_err
  }
  container, container_err := stack_pop(&interp.stack)
  if container_err != nil {
    return container_err
  }

  segments: []Forthic_Value
  if arr, is_array := path.([dynamic]Forthic_Value); is_array {
    segments = arr[:]
  } else {
    segments = []Forthic_Value{path}
  }

  cur := container
  for seg in segments {
    if key, ok := variable_name_from_value(seg); ok {
      rec, is_rec := cur.(Record)
      if !is_rec {
        stack_push(&interp.stack, nil)
        return nil
      }
      cur = rec[Dot_Symbol(key)]
      continue
    }

    if idx, is_int := seg.(i64); is_int {
      arr, is_arr := cur.([dynamic]Forthic_Value)
      if !is_arr || idx < 0 || int(idx) >= len(arr) {
        stack_push(&interp.stack, nil)
        return nil
      }
      cur = arr[idx]
      continue
    }

    stack_push(&interp.stack, nil)
    return nil
  }

  stack_push(&interp.stack, cur)
  return nil
}
