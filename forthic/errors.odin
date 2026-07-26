package forthic

Error :: union {
  Unterminated_String,
  Invalid_Word_Name,
}

Unterminated_String :: struct {
  location: Code_Location,
}

Invalid_Word_Name :: struct {
  note: string,
  location: Code_Location,
}
