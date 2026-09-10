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
  //
  // Every key takes a value, so a literal is strictly alternating key/value and
  // an odd count means a key was left dangling. This is deliberately stricter
  // than defaulting a bare key to `true`: under that rule a value that goes
  // missing is indistinguishable from one intentionally omitted, so a dropped
  // `@` in `{ .file .file @ }` quietly yields flags instead of a lookup and
  // nothing reports it.
  //
  // A Dot_Symbol in value position is still an ordinary value -- `{ .a .b }` is
  // a well-formed pair. Only the count is checked.
  if count % 2 != 0 {
    dangling := ""
    if key, ok := items[count - 1].(Dot_Symbol); ok {
      dangling = string(key)
    }
    return Missing_Record_Value{key = dangling}
  }

  record := make(Record)
  for i := 0; i < count; i += 2 {
    key, ok := items[i].(Dot_Symbol)
    if !ok {
      return Type_Mismatch{note = "Record keys must be Dot_Symbols"}
    }
    record[key] = items[i + 1]
  }

  stack_push(&interp.stack, Forthic_Value(record))
  return nil
}


// ( -- ) -- just records the current stack depth as the record's start
builtin_start_record :: proc(interp: ^Interpreter) -> Error {
  append(&interp.collection_start_positions, Collection_Start{position=stack_len(&interp.stack), kind = .Record})
  return nil
}
