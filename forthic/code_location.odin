package forthic

Position :: struct {
  line: int,
  column: int,
}

Code_Location :: struct {
  start: Position,
  end: Position,
}

Positioned_Forthic :: struct {
  forthic: string,
  location: Maybe(Code_Location)
}
