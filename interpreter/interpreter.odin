package interpreter

message :: proc() -> string {
  return "Forthic!"
}

run :: proc(forthic: string) -> string {
  return forthic
}
