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
  defer delete(token.text)
  testing.expect(t, err == nil)
  testing.expect_value(t, token.token_type, Token_Type.Word)
  testing.expect_value(t, token.text, "DUP")
}

@(test)
test_eos_on_empty_input :: proc(t: ^testing.T) {
  tokenizer := make_tokenizer("")
  defer tokenizer_destroy(&tokenizer)

  token, err := tokenizer_next_token(&tokenizer)
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.token_type, Token_Type.Eos)
}

@(test)
test_eos_after_last_token :: proc(t: ^testing.T) {
  tokenizer := make_tokenizer("DUP")
  defer tokenizer_destroy(&tokenizer)

  first, first_err := tokenizer_next_token(&tokenizer)
  defer delete(first.text)
  testing.expect(t, first_err == nil)
  testing.expect_value(t, first.token_type, Token_Type.Word)

  second, second_err := tokenizer_next_token(&tokenizer)
  defer delete(second.text)
  testing.expect(t, second_err == nil)
  testing.expect_value(t, second.token_type, Token_Type.Eos)
}

@(private)
delete_tokens :: proc(tokens: [dynamic]Token) {
  for token in tokens {
    delete(token.text)
  }
  delete(tokens)
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
test_token_locations :: proc(t: ^testing.T) {
  tokens := tokenize_all("DUP SWAP")
  defer delete_tokens(tokens)

  testing.expect_value(t, tokens[0].location.start, Position{line = 1, column = 1})
  testing.expect_value(t, tokens[0].location.end, Position{line = 1, column = 4})
  testing.expect_value(t, tokens[1].location.start, Position{line = 1, column = 5})
  testing.expect_value(t, tokens[1].location.end, Position{line = 1, column = 9})
}

@(test)
test_token_location_seeded_from_reference :: proc(t: ^testing.T) {
  reference_location := Code_Location{
    start = Position{line = 5, column = 10},
    end   = Position{line = 5, column = 10},
  }
  positioned_forthic := Positioned_Forthic{forthic = "DUP", location = reference_location}

  tokenizer: Tokenizer
  tokenizer_init(&tokenizer, positioned_forthic)
  defer tokenizer_destroy(&tokenizer)

  token, err := tokenizer_next_token(&tokenizer)
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.location.start, Position{line = 5, column = 10})
  testing.expect_value(t, token.location.end, Position{line = 5, column = 13})
}

@(test)
test_comment :: proc(t: ^testing.T) {
  tokens := tokenize_all("DUP # This is a comment\nSWAP")
  defer delete_tokens(tokens)

  testing.expect_value(t, len(tokens), 3)
  testing.expect_value(t, tokens[0].token_type, Token_Type.Word)
  testing.expect_value(t, tokens[1].token_type, Token_Type.Comment)
  testing.expect_value(t, tokens[2].token_type, Token_Type.Word)
}

@(test)
test_definition :: proc(t: ^testing.T) {
  tokens := tokenize_all(": DOUBLE 2 * ;")
  defer delete_tokens(tokens)

  testing.expect_value(t, tokens[0].token_type, Token_Type.StartDef)
  testing.expect_value(t, tokens[0].text, "DOUBLE")
  testing.expect_value(t, tokens[3].token_type, Token_Type.EndDef)
}

@(test)
test_invalid_definition_name :: proc(t: ^testing.T) {
  token, err := gather_first_token(": \"INVALID\" ;")
  defer delete(token.text)

  _, is_invalid_name := err.(Invalid_Word_Name)
  testing.expect(t, is_invalid_name)
}

@(test)
test_memo :: proc(t: ^testing.T) {
  tokens := tokenize_all("@: CACHED 42")
  defer delete_tokens(tokens)

  testing.expect_value(t, tokens[0].token_type, Token_Type.StartMemo)
  testing.expect_value(t, tokens[0].text, "CACHED")
}

@(test)
test_array :: proc(t: ^testing.T) {
  tokens := tokenize_all("[ 1 2 3 ]")
  defer delete_tokens(tokens)

  testing.expect_value(t, len(tokens), 5)
  testing.expect_value(t, tokens[0].token_type, Token_Type.StartArray)
  testing.expect_value(t, tokens[1].token_type, Token_Type.Word)
  testing.expect_value(t, tokens[4].token_type, Token_Type.EndArray)
}

@(test)
test_dot_symbol :: proc(t: ^testing.T) {
  tokens := tokenize_all(".field")
  defer delete_tokens(tokens)

  testing.expect_value(t, len(tokens), 1)
  testing.expect_value(t, tokens[0].token_type, Token_Type.DotSymbol)
  testing.expect_value(t, tokens[0].text, "field")
}

@(test)
test_module :: proc(t: ^testing.T) {
  tokens := tokenize_all("{ : WORD 42 ; }")
  defer delete_tokens(tokens)

  testing.expect_value(t, tokens[0].token_type, Token_Type.StartModule)

  found_end_module := false
  for token in tokens {
    if token.token_type == .EndModule {
      found_end_module = true
    }
  }
  testing.expect(t, found_end_module)
}

@(test)
test_is_single_quote :: proc(t: ^testing.T) {
  tokenizer := make_tokenizer("\"hello\"")
  defer tokenizer_destroy(&tokenizer)
  testing.expect(t, is_single_quote(&tokenizer, '"'))
}

@(test)
test_is_single_quote_rejects_non_quote :: proc(t: ^testing.T) {
  tokenizer := make_tokenizer("hello")
  defer tokenizer_destroy(&tokenizer)
  testing.expect(t, !is_single_quote(&tokenizer, 'h'))
}

@(test)
test_is_single_quote_rejects_triple_quote :: proc(t: ^testing.T) {
  tokenizer := make_tokenizer("\"\"\"multi\nline\"\"\"")
  defer tokenizer_destroy(&tokenizer)
  testing.expect(t, !is_single_quote(&tokenizer, '"'))
}

@(test)
test_string_literal :: proc(t: ^testing.T) {
  tokens := tokenize_all("\"hello world\"")
  defer delete_tokens(tokens)

  testing.expect_value(t, len(tokens), 1)
  testing.expect_value(t, tokens[0].token_type, Token_Type.String)
  testing.expect_value(t, tokens[0].text, "hello world")
}

@(test)
test_string_escape_newline :: proc(t: ^testing.T) {
  // Forthic source: "a\nb" (backslash-n, not a real newline)
  token, err := gather_first_token(`"a\nb"`)
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "a\nb")
}

@(test)
test_string_escape_tab :: proc(t: ^testing.T) {
  token, err := gather_first_token(`"a\tb"`)
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "a\tb")
}

@(test)
test_string_escape_backslash :: proc(t: ^testing.T) {
  // Forthic source: "a\\b" (two literal backslashes) -> one literal backslash
  token, err := gather_first_token(`"a\\b"`)
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, `a\b`)
}

@(test)
test_string_escape_quote :: proc(t: ^testing.T) {
  // Forthic source: "she said \"hi\""
  token, err := gather_first_token(`"she said \"hi\""`)
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, `she said "hi"`)
}

@(test)
test_string_escape_unrecognized_passthrough :: proc(t: ^testing.T) {
  // \U is not a recognized escape, so both the backslash and the char
  // are kept literally -- this preserves things like Windows paths and
  // regex patterns (e.g. \d) that happen to appear in a string.
  token, err := gather_first_token("\"C:\\Users\"")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "C:\\Users")
}

@(test)
test_triple_quote_string :: proc(t: ^testing.T) {
  tokens := tokenize_all("\"\"\"multi\nline\nstring\"\"\"")
  defer delete_tokens(tokens)

  testing.expect_value(t, len(tokens), 1)
  testing.expect_value(t, tokens[0].token_type, Token_Type.String)
  testing.expect_value(t, tokens[0].text, "multi\nline\nstring")
}

@(private)
gather_first_token :: proc(forthic: string) -> (Token, Error) {
  tokenizer := make_tokenizer(forthic)
  defer tokenizer_destroy(&tokenizer)
  return tokenizer_next_token(&tokenizer)
}

@(test)
test_triple_quote_greedy_trailing_apostrophe :: proc(t: ^testing.T) {
  // Closing "'''" is preceded by content ending in an apostrophe, so the
  // apostrophe run at the end is: content 'Hello' + closing '''. The quote
  // right after the candidate close matches the delim, so it's consumed as
  // content (greedy), and the *next* ''' is the real close.
  token, err := gather_first_token("'''I said 'Hello''''")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "I said 'Hello'")
}

@(test)
test_triple_quote_normal_no_greedy :: proc(t: ^testing.T) {
  token, err := gather_first_token("'''Hello'''")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "Hello")
}

@(test)
test_triple_quote_double_quote_greedy :: proc(t: ^testing.T) {
  token, err := gather_first_token("\"\"\"I said \"Hello\"\"\"\"")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "I said \"Hello\"")
}

@(test)
test_triple_quote_six_quotes_is_empty :: proc(t: ^testing.T) {
  token, err := gather_first_token("''''''")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "")
}

@(test)
test_triple_quote_eight_quotes_two_content :: proc(t: ^testing.T) {
  token, err := gather_first_token("''''''''")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "''")
}

@(test)
test_triple_quote_nested_quotes :: proc(t: ^testing.T) {
  token, err := gather_first_token("\"\"\"He said \"I said 'Hello' to you\"\"\"\"")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "He said \"I said 'Hello' to you\"")
}

@(test)
test_triple_quote_no_greedy_when_not_followed_by_quote :: proc(t: ^testing.T) {
  // The first "'''" close here is followed by a space, not another quote,
  // so it should close normally rather than treating it as greedy content.
  token, err := gather_first_token("'''Hello''' world'''")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "Hello")
}

@(test)
test_triple_quote_apostrophes_in_content :: proc(t: ^testing.T) {
  token, err := gather_first_token("'''It's a beautiful day, isn't it?''''")
  defer delete(token.text)

  testing.expect(t, err == nil)
  testing.expect_value(t, token.text, "It's a beautiful day, isn't it?'")
}

@(test)
test_triple_quote_mixed_delimiters_unterminated :: proc(t: ^testing.T) {
  // Opened with ''' but "closed" with """ -- since the delimiters don't
  // match, this never finds a valid close and should be Unterminated_String.
  token, err := gather_first_token("'''Hello\"\"\"")
  defer delete(token.text)

  _, is_unterminated := err.(Unterminated_String)
  testing.expect(t, is_unterminated)
}

@(test)
test_triple_quote_backward_compatibility :: proc(t: ^testing.T) {
  inputs := []string{
    "'''simple'''",
    "'''multi\nline\nstring'''",
    "'''string with \"double quotes\"'''",
    "'''string with 'single quotes'''''",
  }
  expected := []string{
    "simple",
    "multi\nline\nstring",
    "string with \"double quotes\"",
    "string with 'single quotes''",
  }

  for input, i in inputs {
    token, err := gather_first_token(input)
    testing.expect(t, err == nil)
    testing.expect_value(t, token.text, expected[i])
    delete(token.text)
  }
}

@(test)
test_unterminated_string :: proc(t: ^testing.T) {
  tokenizer := make_tokenizer("\"unterminated")
  defer tokenizer_destroy(&tokenizer)

  token, err := tokenizer_next_token(&tokenizer)
  defer delete(token.text)

  _, is_unterminated := err.(Unterminated_String)
  testing.expect(t, is_unterminated)
}
