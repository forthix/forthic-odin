package forthic

Error :: union {
  Unterminated_String,
}

Unterminated_String :: struct {
  location: Code_Location,
}
