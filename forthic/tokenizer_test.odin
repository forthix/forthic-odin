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
