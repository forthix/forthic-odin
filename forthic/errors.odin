package forthic

Error :: union {
  Unterminated_String,
  Invalid_Word_Name,
  Stack_Underflow,
}

Unterminated_String :: struct {
  location: Code_Location,
}

Invalid_Word_Name :: struct {
  note: string,
  location: Code_Location,
}

Stack_Underflow :: struct {}

