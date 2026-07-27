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
