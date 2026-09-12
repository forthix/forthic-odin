package forthic

import "core:slice"
import "core:strings"

Collection_Kind :: enum { Array, Record }

// The open marker a collection literal leaves on the stack.
//
// `[` and `{` push one of these, and `]` and `}` fold the stack back to the
// matching one. It is deliberately a Forthic *value* rather than a side table of
// stack depths. A depth is only right as long as nothing disturbs the stack
// under it, so a word reaching below the opener corrupted the count silently:
// `1 2 [ DROP 3 ]` captured no items at all and reported nothing, even though
// `3` was pushed inside the literal. A mark is found by popping, so it cannot be
// stepped over -- consume it and `]` runs the stack dry and says so.
//
// It carries the opener's location and nothing else, so a mismatch can point at
// the `[` or `{` left unclosed rather than at the close word that tripped over
// it.
//
// Making the marker a value is also what keeps `[` a word rather than syntax:
// words can move it. `1 [ SWAP ]` pulls an outer value into the array, and
// `: MARK [ ;` factors the opener into a definition.
Collection_Mark :: struct {
  kind: Collection_Kind,
  location: Code_Location,
}

// The delimiters a kind is written with, so an error can name them.
collection_open :: proc(kind: Collection_Kind) -> string {
  switch kind {
  case .Array:  return "["
  case .Record: return "{"
  }
  return ""
}

collection_close :: proc(kind: Collection_Kind) -> string {
  switch kind {
  case .Array:  return "]"
  case .Record: return "}"
  }
  return ""
}

// A mark prints as its opener in angle brackets. It is interpreter state that
// happens to sit on the stack, so it should not read as the string "[".
collection_mark_to_string :: proc(mark: Collection_Mark) -> string {
  switch mark.kind {
  case .Array:  return "<[>"
  case .Record: return "<{>"
  }
  return "<?>"
}

// `expected` is the literal this close word belongs to, `got` the still-open
// inner one it reached instead. The message points at the inner opener rather
// than the close word that tripped over it: the close word is where the error
// surfaces, but the missing delimiter is what the author has to add.
mismatched_collection_note :: proc(expected, got: Collection_Kind) -> string {
  return strings.concatenate({
    "Mismatched '", collection_close(expected),
    "' -- an unclosed '", collection_open(got),
    "' is open inside this '", collection_open(expected),
    "'. Add the '", collection_close(got), "' it needs",
  })
}

// ( ...items -- array ) -- everything pushed since the matching [
builtin_end_array :: proc(interp: ^Interpreter) -> Error {
  items := make([dynamic]Forthic_Value, 0)

  for {
    if stack_is_empty(&interp.stack) {
      // Running the stack dry means there is no `[` to fold back to -- either
      // none was written, or a word consumed the mark. Say that, rather than
      // reporting the underflow it looks like from in here.
      delete(items)
      return Unmatched_Collection_Close{
        kind = .Array,
        note = "] with no open array literal",
      }
    }

    v, err := stack_pop(&interp.stack)
    if err != nil {
      delete(items)
      return err
    }

    if mark, is_mark := v.(Collection_Mark); is_mark {
      if mark.kind == .Array {
        break
      }
      // A record mark down here means the `{` it came from was never closed.
      // It is not a delimiter to this word, so without this check it would be
      // collected as an ordinary item and land inside the array.
      delete(items)
      return Mismatched_Collection{
        expected = .Array,
        got = mark.kind,
        note = mismatched_collection_note(.Array, mark.kind),
        location = mark.location,
      }
    }

    // See builtin_end_record: a Dot_Symbol only exists so `}` can tell a key
    // from a value. An element that lands in data is an ordinary string.
    if symbol, is_symbol := v.(Dot_Symbol); is_symbol {
      v = string(symbol)
    }
    append(&items, v)
  }

  slice.reverse(items[:])
  stack_push(&interp.stack, Forthic_Value(items))
  return nil
}

// ( ...key-value-pairs -- record ) -- everything pushed since the matching {
builtin_end_record :: proc(interp: ^Interpreter) -> Error {
  items := make([dynamic]Forthic_Value, 0)
  defer delete(items)

  for {
    if stack_is_empty(&interp.stack) {
      return Unmatched_Collection_Close{
        kind = .Record,
        note = "} with no open record literal",
      }
    }

    v, err := stack_pop(&interp.stack)
    if err != nil {
      return err
    }

    if mark, is_mark := v.(Collection_Mark); is_mark {
      if mark.kind == .Record {
        break
      }
      // The mirror of the case in builtin_end_array: an array mark here means
      // the `[` it came from was never closed, and left unchecked it would be
      // folded into the record as an ordinary item -- at an even item count, so
      // the key/value rule below would see nothing wrong either.
      return Mismatched_Collection{
        expected = .Record,
        got = mark.kind,
        note = mismatched_collection_note(.Record, mark.kind),
        location = mark.location,
      }
    }

    append(&items, v)
  }

  slice.reverse(items[:])
  count := len(items)

  // Convert into record and push onto stack.
  //
  // Every key takes a value, so a literal is strictly alternating key/value and
  // an odd count means a key was left dangling. This is deliberately stricter
  // than defaulting a bare key to `true`: under that rule `{ .a 1 .b }` is a
  // well-formed record with `b: true`, so a value the author meant to write and
  // didn't looks exactly like a flag they meant to set.
  //
  // What it does NOT catch is a dropped `@`. `@` is stack-neutral, so
  // `{ .file .file }` closes with the same item count as `{ .file .file @ }` and
  // silently stores the string "file". The check for that is rejecting a
  // Dot_Symbol in value position, which is a separate rule this is not: here a
  // Dot_Symbol in value position is still an ordinary string, so `{ .a .b }` is
  // a well-formed pair. Only the count is checked.
  if count % 2 != 0 {
    if key, ok := items[count - 1].(Dot_Symbol); ok {
      return Missing_Record_Value{
        key = string(key),
        note = strings.concatenate({
          "Record key .", string(key),
          " has no value. Every key in a { } literal takes one -- write { .",
          string(key), " value }",
        }),
      }
    }
    return Missing_Record_Value{
      note = "Record literal has an odd number of items, so a key was left without a value",
    }
  }

  record := make(Record)
  for i := 0; i < count; i += 2 {
    key, ok := items[i].(Dot_Symbol)
    if !ok {
      return Type_Mismatch{note = "Record keys must be Dot_Symbols"}
    }
    // A Dot_Symbol is a parse-time distinction that lets `}` tell a key from a
    // value. Once it lands in data it is an ordinary string, so unwrap it here:
    // left as a Dot_Symbol it would print like a string yet compare unequal to
    // one, and `{ .a .b } .a JQ@ "b" ==` would be false.
    value := items[i + 1]
    if symbol, is_symbol := value.(Dot_Symbol); is_symbol {
      value = string(symbol)
    }
    record[key] = value
  }

  stack_push(&interp.stack, Forthic_Value(record))
  return nil
}
