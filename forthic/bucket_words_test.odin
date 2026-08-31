package forthic

import "core:testing"

@(test)
test_bucket_picks_first_matching_breakpoint :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  // Key values here are strings, not dot-symbols: a dot-symbol key
  // immediately followed by a dot-symbol value is parsed as a bare
  // boolean flag, not a key/value pair (see collection_words.odin).
  err := run_forthic(&interp, `
    0    [ { .below 0 .key "low" } { .below 0.5 .key "medium" } ] "high" BUCKET
    0.25 [ { .below 0 .key "low" } { .below 0.5 .key "medium" } ] "high" BUCKET
    0.5  [ { .below 0 .key "low" } { .below 0.5 .key "medium" } ] "high" BUCKET
    1.0  [ { .below 0 .key "low" } { .below 0.5 .key "medium" } ] "high" BUCKET
  `)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 4)

  a, _ := stack_get(&interp.stack, 0)
  b, _ := stack_get(&interp.stack, 1)
  c, _ := stack_get(&interp.stack, 2)
  d, _ := stack_get(&interp.stack, 3)
  testing.expect(t, forthic_value_equal(a, Forthic_Value(string("low"))))
  testing.expect(t, forthic_value_equal(b, Forthic_Value(string("medium"))))
  testing.expect(t, forthic_value_equal(c, Forthic_Value(string("medium"))))
  testing.expect(t, forthic_value_equal(d, Forthic_Value(string("high"))))
}

@(test)
test_bucket_type_mismatch_on_non_numeric_value :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `"nope" [ ] "high" BUCKET`)
  _, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}
