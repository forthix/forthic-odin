package forthic

import "core:os"

Error :: union {
  Unterminated_String,
  Invalid_Word_Name,
  Stack_Underflow,
  Type_Mismatch,
  Missing_Record_Value,
  Mismatched_Collection,
  Unmatched_Collection_Close,
  Unknown_Word,
  Unknown_Variable,
  Division_By_Zero,
  Missing_Semicolon,
  Extra_Semicolon,
  Extra_End_Module,
  Read_File_Error,
}

Unterminated_String :: struct {
  location: Code_Location,
}

Invalid_Word_Name :: struct {
  note: string,
  location: Code_Location,
}

Stack_Underflow :: struct {}

Type_Mismatch :: struct {
  note: string,
  location: Code_Location,
}

// A record literal key that was left without a value. Every key in a `{ }`
// literal takes one, so an odd number of items means a value went missing --
// which a bare-flag default would have silently accepted as intentional.
Missing_Record_Value :: struct {
  key: string,
  note: string,
  location: Code_Location,
}

// A `}` that reached a `[`, or a `]` that reached a `{` -- the inner literal was
// never closed.
//
// Worth its own error because the alternative is silence: a close word matches
// only its own opening mark, so the other one is not a delimiter to it, and
// without this check it is collected as an ordinary item and ends up *inside*
// the collection being built -- at an item count the key/value rule sees nothing
// wrong with.
Mismatched_Collection :: struct {
  expected: Collection_Kind,
  got: Collection_Kind,
  note: string,
  location: Code_Location,
}

// A `]` or `}` with no matching opener. Without this the close words pop an
// empty start-position stack, which aborts the process instead of reporting a
// plain syntax error.
Unmatched_Collection_Close :: struct {
  kind: Collection_Kind,
  note: string,
  location: Code_Location,
}

Unknown_Word :: struct {
  word: string,
  location: Code_Location,
}

Unknown_Variable :: struct {
  name: string,
  location: Code_Location,
}

Division_By_Zero :: struct {
  location: Code_Location,
}

Missing_Semicolon :: struct {
  location: Code_Location,
}

Extra_Semicolon :: struct {
  location: Code_Location,
}

Extra_End_Module :: struct {
  location: Code_Location,
}

Read_File_Error :: struct {
  path: string,
  err: os.Error,
}
