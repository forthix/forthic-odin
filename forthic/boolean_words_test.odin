package forthic

import "core:testing"

@(test)
test_equal_and_not_equal :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `1 1 == 1 2 == 1 1 != 1 2 !=`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 4)

  a, _ := stack_get(&interp.stack, 0)
  b, _ := stack_get(&interp.stack, 1)
  c, _ := stack_get(&interp.stack, 2)
  d, _ := stack_get(&interp.stack, 3)
  testing.expect(t, forthic_value_equal(a, Forthic_Value(bool(true))))
  testing.expect(t, forthic_value_equal(b, Forthic_Value(bool(false))))
  testing.expect(t, forthic_value_equal(c, Forthic_Value(bool(false))))
  testing.expect(t, forthic_value_equal(d, Forthic_Value(bool(true))))
}

@(test)
test_numeric_comparisons :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `1 2 < 2 1 < 1 1 <= 2 1 > 1 2 > 1 1 >=`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 6)

  results := [6]bool{true, false, true, true, false, true}
  for i in 0..<6 {
    v, _ := stack_get(&interp.stack, i)
    testing.expect(t, forthic_value_equal(v, Forthic_Value(bool(results[i]))))
  }
}

@(test)
test_comparison_type_mismatch :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `"a" "b" <`)
  _, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}

@(test)
test_boolean_logic :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `TRUE NOT TRUE FALSE AND TRUE FALSE OR`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 3)

  a, _ := stack_get(&interp.stack, 0)
  b, _ := stack_get(&interp.stack, 1)
  c, _ := stack_get(&interp.stack, 2)
  testing.expect(t, forthic_value_equal(a, Forthic_Value(bool(false))))
  testing.expect(t, forthic_value_equal(b, Forthic_Value(bool(false))))
  testing.expect(t, forthic_value_equal(c, Forthic_Value(bool(true))))
}
