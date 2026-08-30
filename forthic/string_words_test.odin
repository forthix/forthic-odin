package forthic

import "core:testing"

@(test)
test_to_str_converts_common_types :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `5 >STR TRUE >STR "hi" >STR`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 3)

  a, _ := stack_get(&interp.stack, 0)
  b, _ := stack_get(&interp.stack, 1)
  c, _ := stack_get(&interp.stack, 2)
  testing.expect(t, forthic_value_equal(a, Forthic_Value(string("5"))))
  testing.expect(t, forthic_value_equal(b, Forthic_Value(string("true"))))
  testing.expect(t, forthic_value_equal(c, Forthic_Value(string("hi"))))
}

@(test)
test_concat_joins_strings :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ "Turn " "5" ": " "hi" ] CONCAT`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(string("Turn 5: hi"))))
}
