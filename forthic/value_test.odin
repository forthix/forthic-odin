package forthic

import "core:testing"

@(test)
test_forthic_value_equal_dot_symbol :: proc(t: ^testing.T) {
  a := Forthic_Value(Dot_Symbol("flag"))
  b := Forthic_Value(Dot_Symbol("flag"))
  testing.expect(t, forthic_value_equal(a, b))
}

@(test)
test_forthic_value_equal_dot_symbol_different_text :: proc(t: ^testing.T) {
  a := Forthic_Value(Dot_Symbol("flag"))
  b := Forthic_Value(Dot_Symbol("other"))
  testing.expect(t, !forthic_value_equal(a, b))
}

@(test)
test_forthic_value_equal_dot_symbol_not_equal_to_string :: proc(t: ^testing.T) {
  a := Forthic_Value(Dot_Symbol("flag"))
  b := Forthic_Value(string("flag"))
  testing.expect(t, !forthic_value_equal(a, b))
}
