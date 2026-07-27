package forthic

import "core:slice"

Collection_Kind :: enum { Array, Record }

Collection_Start :: struct {
  position: int,
  kind: Collection_Kind,
}

native_start_array :: proc(interp: ^Interpreter) -> Error {
  append(&interp.collection_start_positions, Collection_Start{position=stack_len(&interp.stack), kind = .Array})
  return nil
}


native_end_array :: proc(interp: ^Interpreter) -> Error {
  start := pop(&interp.collection_start_positions)
  if start.kind != .Array {
    return Mismatched_Collection{
      expected = .Array,
      got = start.kind,
      // location = ?
    }
  }
  count := stack_len(&interp.stack) - start.position
  if count < 0 {
    return Stack_Underflow{}
  }

  items := make([dynamic]Forthic_Value, 0, count)
  for _ in 0..<count {
    v, err := stack_pop(&interp.stack)
    if err != nil  {
      return err
    }
    append(&items, v)
  }
  slice.reverse(items[:])
  stack_push(&interp.stack, Forthic_Value(items))
  return nil
}

native_end_record :: proc(interp: ^Interpreter) -> Error {
  start := pop(&interp.collection_start_positions)
  if start.kind != .Record {
    return Mismatched_Collection{
      expected = .Record,
      got = start.kind,
      // location = ?
    }
  }
  count := stack_len(&interp.stack) - start.position
  if count < 0 {
    return Stack_Underflow{}
  }

  if count % 2 != 0 {
    return Invalid_Record{ count = count }
  }

  items := make([dynamic]Forthic_Value, 0, count)
  defer delete(items)
  for _ in 0..<count {
    v, err := stack_pop(&interp.stack)
    if err != nil  {
      return err
    }
    append(&items, v)
  }
  slice.reverse(items[:])

  // Convert into record and push onto stack
  record := make(map[string]Forthic_Value)
  for i := 0; i < count; i += 2 {
    key, ok := items[i].(string)
    if !ok {
      return Type_Mismatch{note = "Record keys must be strings"}
    }
    record[key] = items[i + 1]
  }

  stack_push(&interp.stack, Forthic_Value(record))
  return nil
}


native_start_record :: proc(interp: ^Interpreter) -> Error {
  append(&interp.collection_start_positions, Collection_Start{position=stack_len(&interp.stack), kind = .Record})
  return nil
}
