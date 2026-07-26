package forthic

import "core:testing"

@(private)
make_tokenizer :: proc(forthic: string) -> Tokenizer {
  positioned_forthic := Positioned_Forthic{forthic = forthic, location = nil}

  tokenizer: Tokenizer
  tokenizer_init(&tokenizer, positioned_forthic)
  return tokenizer
}

@(test)
test_tokenize_single_word :: proc(t: ^testing.T) {
  tokenizer := make_tokenizer("DUP")
  defer tokenizer_destroy(&tokenizer)

  token, err := tokenizer_next_token(&tokenizer)
  testing.expect(t, err == nil)
  testing.expect_value(t, token.token_type, Token_Type.Word)
  testing.expect_value(t, token.text, "DUP")
}

@(private)
tokenize_all :: proc(forthic: string) -> [dynamic]Token {
  tokenizer := make_tokenizer(forthic)
  defer tokenizer_destroy(&tokenizer)

  tokens: [dynamic]Token
  for {
    token, err := tokenizer_next_token(&tokenizer)
    if err != nil {
      break
    }
    if token.token_type == .Eos {
      break
    }
    append(&tokens, token)
  }
  return tokens
}

@(test)
test_comment :: proc(t: ^testing.T) {
  tokens := tokenize_all("DUP # This is a comment\nSWAP")
  defer delete(tokens)

  testing.expect_value(t, len(tokens), 3)
  testing.expect_value(t, tokens[0].token_type, Token_Type.Word)
  testing.expect_value(t, tokens[1].token_type, Token_Type.Comment)
  testing.expect_value(t, tokens[2].token_type, Token_Type.Word)
}
