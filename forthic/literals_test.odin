package forthic

import "core:testing"

@(test)
test_literal_to_bool_true :: proc(t: ^testing.T) {
  value, ok := literal_to_bool("TRUE")
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(value, Forthic_Value(bool(true))))
}

@(test)
test_literal_to_bool_false :: proc(t: ^testing.T) {
  value, ok := literal_to_bool("FALSE")
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(value, Forthic_Value(bool(false))))
}

@(test)
test_literal_to_bool_lowercase_not_recognized :: proc(t: ^testing.T) {
  _, ok := literal_to_bool("true")
  testing.expect(t, !ok)
}

@(test)
test_literal_to_bool_unrelated_word_not_recognized :: proc(t: ^testing.T) {
  _, ok := literal_to_bool("DUP")
  testing.expect(t, !ok)
}

@(test)
test_literal_to_float_basic :: proc(t: ^testing.T) {
  value, ok := literal_to_float("3.14")
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(value, Forthic_Value(f64(3.14))))
}

@(test)
test_literal_to_float_negative :: proc(t: ^testing.T) {
  value, ok := literal_to_float("-2.5")
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(value, Forthic_Value(f64(-2.5))))
}

@(test)
test_literal_to_float_requires_decimal_point :: proc(t: ^testing.T) {
  _, ok := literal_to_float("42")
  testing.expect(t, !ok)
}

@(test)
test_literal_to_float_invalid :: proc(t: ^testing.T) {
  _, ok := literal_to_float("abc.def")
  testing.expect(t, !ok)
}

@(test)
test_literal_to_int_basic :: proc(t: ^testing.T) {
  value, ok := literal_to_int("42")
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(value, Forthic_Value(i64(42))))
}

@(test)
test_literal_to_int_negative :: proc(t: ^testing.T) {
  value, ok := literal_to_int("-10")
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(value, Forthic_Value(i64(-10))))
}

@(test)
test_literal_to_int_rejects_decimal_point :: proc(t: ^testing.T) {
  _, ok := literal_to_int("3.14")
  testing.expect(t, !ok)
}

@(test)
test_literal_to_int_rejects_trailing_garbage :: proc(t: ^testing.T) {
  _, ok := literal_to_int("42abc")
  testing.expect(t, !ok)
}
