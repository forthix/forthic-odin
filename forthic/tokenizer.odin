package forthic

import "core:strings"
import "core:unicode/utf8"

Token_Type :: enum {
  Word,
  Comment,
  Eos,
}

Token :: struct {
  token_type: Token_Type,
  text: string,
  location: Code_Location
}

Tokenizer :: struct {
  reference_location: Maybe(Code_Location),

  input_string: string,
  byte_pos: int,
  line: int,
  column: int,

  // Token tracking
  token_start_pos: int,
  token_line: int,
  token_column: int,
}

tokenizer_init :: proc(tokenizer: ^Tokenizer, positioned_forthic: Positioned_Forthic) {
  tokenizer.reference_location = positioned_forthic.location
  tokenizer.input_string = positioned_forthic.forthic
}

tokenizer_destroy :: proc(tokenizer: ^Tokenizer) {
}


tokenizer_next_token :: proc(tokenizer: ^Tokenizer) -> (Token, Error) {
  // NOTE: In Odin, len of string is in *bytes* not necessarily characters, so this is ok
  for tokenizer.byte_pos < len(tokenizer.input_string) {
    ch, ok := tokenizer_peek(tokenizer)
    if !ok {
      break
    }

    switch {
      case is_whitespace(ch):
        tokenizer_advance(tokenizer)
        continue
      case ch == '#':
        return tokenizer_transition_from_comment(tokenizer)
      case:
        return tokenizer_transition_from_word(tokenizer)
    }
  }
  return end_of_stream_token(tokenizer), nil
}


tokenizer_transition_from_word :: proc(tokenizer: ^Tokenizer) -> (Token, Error) {
  tokenizer_note_start_token(tokenizer)

  for tokenizer.byte_pos < len(tokenizer.input_string) {
    ch, ok := tokenizer_peek(tokenizer)
    if !ok || is_whitespace(ch) {
      break
    }
    tokenizer_advance(tokenizer)
  }

  text := strings.clone(tokenizer.input_string[tokenizer.token_start_pos:tokenizer.byte_pos])
  return Token{
    token_type = .Word,
    text = text,
    location = tokenizer_token_location(tokenizer),
  }, nil
}

tokenizer_transition_from_comment :: proc(tokenizer: ^Tokenizer) -> (Token, Error) {
  tokenizer_note_start_token(tokenizer)

  for tokenizer.byte_pos < len(tokenizer.input_string) {
    ch, ok := tokenizer_peek(tokenizer)
    if !ok || ch == '\n' {
      break
    }
    tokenizer_advance(tokenizer)
  }

  text := strings.clone(tokenizer.input_string[tokenizer.token_start_pos:tokenizer.byte_pos])
  return Token{
    token_type = .Comment,
    text = text,
    location = tokenizer_token_location(tokenizer),
  }, nil
}

// ----------------------------------------------------------------------------
// Support

tokenizer_advance :: proc(tokenizer: ^Tokenizer) -> rune {
  r, width := utf8.decode_rune_in_string(tokenizer.input_string[tokenizer.byte_pos:])
  tokenizer.byte_pos += width
  if r == '\n' {
    tokenizer.line += 1
    tokenizer.column = 1
  }
  else {
    tokenizer.column += 1
  }
  return r;
}

is_whitespace :: proc(ch: rune) -> bool {
  switch ch {
    case ' ', '\t', '\n', '\r':
      return true
    case:
      return false
  }
}

tokenizer_note_start_token :: proc(tokenizer: ^Tokenizer) {
  tokenizer.token_start_pos = tokenizer.byte_pos
  tokenizer.token_line = tokenizer.line
  tokenizer.token_column = tokenizer.column
}

tokenizer_token_location :: proc(tokenizer: ^Tokenizer) -> Code_Location {
  return Code_Location{
    start = Position{line = tokenizer.token_line, column = tokenizer.token_column},
    end   = Position{line = tokenizer.line, column = tokenizer.column},
  }
}

end_of_stream_token :: proc(tokenizer: ^Tokenizer) -> Token {
  return Token{
    token_type = .Eos,
    text       = "",
    location   = tokenizer_token_location(tokenizer),
  }
}


tokenizer_peek :: proc(tokenizer: ^Tokenizer, offset := 0) -> (rune, bool) {
  pos := tokenizer.byte_pos
  r: rune
  ok := true

  // Since we don't know how many bytes the characters are, we need to decode step-by-step
  for _ in 0..=offset {
    if  pos >= len(tokenizer.input_string) {
      return 0, false
    }

    width: int
    r, width = utf8.decode_rune_in_string(tokenizer.input_string[pos:])
    pos += width
  }
  return r, ok
}
