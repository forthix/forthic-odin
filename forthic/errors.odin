package forthic

Error :: union {
  Unterminated_String,
  Invalid_Word_Name,
  Stack_Underflow,
  Type_Mismatch,
  Mismatched_Collection,
  Unknown_Word,
  Division_By_Zero,
  Missing_Semicolon,
  Extra_Semicolon,
  Extra_End_Module,
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

Mismatched_Collection :: struct {
  expected: Collection_Kind,
  got: Collection_Kind,
  location: Code_Location,
}

Unknown_Word :: struct {
  word: string,
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
