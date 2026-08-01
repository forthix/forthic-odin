package forthic

import "core:testing"

@(test)
test_word_options_from_record :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["width"] = Forthic_Value(i64(800))

  opts := word_options_from_record(record)
  testing.expect_value(t, len(opts.values), 1)
}

@(test)
test_word_options_get_bool_present :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["with_key"] = Forthic_Value(bool(true))

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_bool(opts, "with_key", false), true)
}

@(test)
test_word_options_get_bool_missing_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_bool(opts, "with_key", true), true)
  testing.expect_value(t, word_options_get_bool(opts, "with_key", false), false)
}

@(test)
test_word_options_get_bool_wrong_type_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["with_key"] = Forthic_Value(i64(42))

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_bool(opts, "with_key", false), false)
}

@(test)
test_word_options_get_int_present :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["depth"] = Forthic_Value(i64(3))

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_int(opts, "depth", 0), i64(3))
}

@(test)
test_word_options_get_int_missing_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_int(opts, "depth", 7), i64(7))
}

@(test)
test_word_options_get_int_wrong_type_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["depth"] = Forthic_Value(string("not a number"))

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_int(opts, "depth", 7), i64(7))
}

@(test)
test_word_options_get_float_present :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["ratio"] = Forthic_Value(f64(3.25))

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_float(opts, "ratio", 0), f64(3.25))
}

@(test)
test_word_options_get_float_missing_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_float(opts, "ratio", 1.5), f64(1.5))
}

@(test)
test_word_options_get_float_wrong_type_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["ratio"] = Forthic_Value(bool(true))

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_float(opts, "ratio", 1.5), f64(1.5))
}

@(test)
test_word_options_get_string_present :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["title"] = Forthic_Value(string("Game"))

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_string(opts, "title", "default"), "Game")
}

@(test)
test_word_options_get_string_missing_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_string(opts, "title", "Untitled"), "Untitled")
}

@(test)
test_word_options_get_string_wrong_type_returns_default :: proc(t: ^testing.T) {
  record := make(Record)
  defer delete(record)
  record["title"] = Forthic_Value(i64(42))

  opts := word_options_from_record(record)
  testing.expect_value(t, word_options_get_string(opts, "title", "Untitled"), "Untitled")
}
