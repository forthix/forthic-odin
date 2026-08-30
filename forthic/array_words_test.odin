package forthic

import "core:testing"

@(test)
test_length_of_array_and_record :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ 1 2 3 ] LENGTH { .a 1 .b 2 } LENGTH`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 2)

  a, _ := stack_get(&interp.stack, 0)
  b, _ := stack_get(&interp.stack, 1)
  testing.expect(t, forthic_value_equal(a, Forthic_Value(i64(3))))
  testing.expect(t, forthic_value_equal(b, Forthic_Value(i64(2))))
}

@(test)
test_nth_returns_element_or_nil :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ 10 20 30 ] 1 NTH`)
  testing.expect(t, err == nil)
  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(20))))

  err = run_forthic(&interp, `[ 10 20 30 ] 99 NTH`)
  testing.expect(t, err == nil)
  top2, pop_err2 := stack_pop(&interp.stack)
  testing.expect(t, pop_err2 == nil)
  testing.expect(t, top2 == nil)
}
