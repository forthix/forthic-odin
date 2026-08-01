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

@(test)
test_record_get_bool_present :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["with_key"] = Forthic_Value(bool(true))

  testing.expect_value(t, record_get_bool(record, "with_key", false), true)
}

@(test)
test_record_get_bool_missing_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)

  testing.expect_value(t, record_get_bool(record, "with_key", true), true)
  testing.expect_value(t, record_get_bool(record, "with_key", false), false)
}

@(test)
test_record_get_bool_wrong_type_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["with_key"] = Forthic_Value(i64(42))

  testing.expect_value(t, record_get_bool(record, "with_key", false), false)
}

@(test)
test_record_get_int_present :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["depth"] = Forthic_Value(i64(3))

  testing.expect_value(t, record_get_int(record, "depth", 0), i64(3))
}

@(test)
test_record_get_int_missing_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)

  testing.expect_value(t, record_get_int(record, "depth", 7), i64(7))
}

@(test)
test_record_get_int_wrong_type_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["depth"] = Forthic_Value(string("not a number"))

  testing.expect_value(t, record_get_int(record, "depth", 7), i64(7))
}

@(test)
test_record_get_float_present :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["ratio"] = Forthic_Value(f64(3.25))

  testing.expect_value(t, record_get_float(record, "ratio", 0), f64(3.25))
}

@(test)
test_record_get_float_missing_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)

  testing.expect_value(t, record_get_float(record, "ratio", 1.5), f64(1.5))
}

@(test)
test_record_get_float_wrong_type_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["ratio"] = Forthic_Value(bool(true))

  testing.expect_value(t, record_get_float(record, "ratio", 1.5), f64(1.5))
}

@(test)
test_record_get_string_present :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["title"] = Forthic_Value(string("Game"))

  testing.expect_value(t, record_get_string(record, "title", "default"), "Game")
}

@(test)
test_record_get_string_missing_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)

  testing.expect_value(t, record_get_string(record, "title", "Untitled"), "Untitled")
}

@(test)
test_record_get_string_wrong_type_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["title"] = Forthic_Value(i64(42))

  testing.expect_value(t, record_get_string(record, "title", "Untitled"), "Untitled")
}
