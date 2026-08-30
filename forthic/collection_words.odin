package forthic

import "core:slice"

Collection_Kind :: enum { Array, Record }

Collection_Start :: struct {
  position: int,
  kind: Collection_Kind,
}

// ( -- ) -- just records the current stack depth as the array's start
builtin_start_array :: proc(interp: ^Interpreter) -> Error {
  append(&interp.collection_start_positions, Collection_Start{position=stack_len(&interp.stack), kind = .Array})
  return nil
}


// ( ...items -- array ) -- everything pushed since the matching [
builtin_end_array :: proc(interp: ^Interpreter) -> Error {
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

// ( ...key-value-pairs -- record ) -- everything pushed since the matching {
builtin_end_record :: proc(interp: ^Interpreter) -> Error {
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

  // Convert into record and push onto stack.
  // A bare flag (a Dot_Symbol key with no following value -- either
  // because another key follows immediately, or because it is the last
  // item) defaults to `true`.
  record := make(Record)
  i := 0
  for i < count {
    key, ok := items[i].(Dot_Symbol)
    if !ok {
      return Type_Mismatch{note = "Record keys must be Dot_Symbols"}
    }

    if i + 1 < count {
      if _, next_is_key := items[i + 1].(Dot_Symbol); !next_is_key {
        record[key] = items[i + 1]
        i += 2
        continue
      }
    }

    record[key] = Forthic_Value(bool(true))
    i += 1
  }

  stack_push(&interp.stack, Forthic_Value(record))
  return nil
}


// ( -- ) -- just records the current stack depth as the record's start
builtin_start_record :: proc(interp: ^Interpreter) -> Error {
  append(&interp.collection_start_positions, Collection_Start{position=stack_len(&interp.stack), kind = .Record})
  return nil
}
