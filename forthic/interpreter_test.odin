package forthic

import "core:testing"

@(private)
run_forthic :: proc(interp: ^Interpreter, forthic: string) -> Error {
  positioned_forthic := Positioned_Forthic{forthic = forthic, location = nil}
  return interpreter_run(interp, positioned_forthic)
}

@(test)
test_interpreter_add :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "2 3 +")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(5))))
}

@(test)
test_interpreter_subtract :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "5 3 -")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(2))))
}

@(test)
test_interpreter_multiply :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "4 3 *")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(12))))
}

@(test)
test_interpreter_divide_exact :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "6 3 /")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(2))))
}

@(test)
test_interpreter_divide_fractional :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "7 2 /")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(f64(3.5))))
}

@(test)
test_interpreter_divide_by_zero :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "5 0 /")
  _, is_div_by_zero := err.(Division_By_Zero)
  testing.expect(t, is_div_by_zero)
}

@(test)
test_interpreter_add_type_mismatch :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "\"a\" 3 +")
  mismatch, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
  testing.expect_value(t, mismatch.note, "+ requires two numbers")
}

@(test)
test_interpreter_drop :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "1 2 DROP")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, top_err := stack_pop(&interp.stack)
  testing.expect(t, top_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(1))))
}

@(test)
test_interpreter_drop_empty_stack :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "DROP")
  _, is_underflow := err.(Stack_Underflow)
  testing.expect(t, is_underflow)
}

@(test)
test_interpreter_dup :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "5 DUP")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 2)

  top, top_err := stack_pop(&interp.stack)
  testing.expect(t, top_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(5))))

  second, second_err := stack_pop(&interp.stack)
  testing.expect(t, second_err == nil)
  testing.expect(t, forthic_value_equal(second, Forthic_Value(i64(5))))
}

@(test)
test_interpreter_swap :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "1 2 SWAP")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 2)

  top, top_err := stack_pop(&interp.stack)
  testing.expect(t, top_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(1))))

  second, second_err := stack_pop(&interp.stack)
  testing.expect(t, second_err == nil)
  testing.expect(t, forthic_value_equal(second, Forthic_Value(i64(2))))
}

@(test)
test_interpreter_simple_definition :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err1 := run_forthic(&interp, ": FORTY-TWO 42 ;")
  testing.expect(t, err1 == nil)

  err2 := run_forthic(&interp, "FORTY-TWO")
  testing.expect(t, err2 == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(42))))
}

@(test)
test_interpreter_definition_with_multiple_values :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err1 := run_forthic(&interp, ": NUMS 1 2 3 ;")
  testing.expect(t, err1 == nil)

  err2 := run_forthic(&interp, "NUMS")
  testing.expect(t, err2 == nil)

  testing.expect_value(t, stack_len(&interp.stack), 3)

  v3, err3 := stack_pop(&interp.stack)
  testing.expect(t, err3 == nil)
  testing.expect(t, forthic_value_equal(v3, Forthic_Value(i64(3))))

  v2, err_v2 := stack_pop(&interp.stack)
  testing.expect(t, err_v2 == nil)
  testing.expect(t, forthic_value_equal(v2, Forthic_Value(i64(2))))

  v1, err_v1 := stack_pop(&interp.stack)
  testing.expect(t, err_v1 == nil)
  testing.expect(t, forthic_value_equal(v1, Forthic_Value(i64(1))))
}

@(test)
test_interpreter_array :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "[ 1 2 3 ]")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected: [dynamic]Forthic_Value
  defer delete(expected)
  append(&expected, Forthic_Value(i64(1)))
  append(&expected, Forthic_Value(i64(2)))
  append(&expected, Forthic_Value(i64(3)))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

@(test)
test_interpreter_word_doc :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  forthic := "#: Adds two to a number.\n#: @effect ( n -- n+2 )\n#: @example 5 PLUS-TWO  # => 7\n: PLUS-TWO 2 + ;"
  err := run_forthic(&interp, forthic)
  testing.expect(t, err == nil)

  app_module := interp.module_stack[0]
  word, found := module_find_word(app_module, "PLUS-TWO")
  testing.expect(t, found)

  doc, has_doc := word.doc.?
  testing.expect(t, has_doc)
  testing.expect_value(t, doc.description, "Adds two to a number.")
  testing.expect_value(t, doc.stack_effect, "( n -- n+2 )")
  testing.expect_value(t, len(doc.examples), 1)
  testing.expect_value(t, doc.examples[0], "5 PLUS-TWO  # => 7")
}

@(test)
test_interpreter_record :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .name \"Player One\" .score 100 }")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make(map[string]Forthic_Value)
  defer delete(expected)
  expected["name"] = Forthic_Value("Player One")
  expected["score"] = Forthic_Value(i64(100))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}
