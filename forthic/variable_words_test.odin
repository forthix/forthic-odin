package forthic

import "core:testing"

@(test)
test_variables_declares_with_nil_default :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ .x ] VARIABLES .x @`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, top == nil)
}

@(test)
test_set_and_get_variable_auto_declares :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `5 .x ! .x @`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(5))))
}

@(test)
test_set_and_get_variable_returns_value :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `5 .x !@`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(5))))
}

@(test)
test_get_undeclared_variable_errors :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `.nope @`)
  _, is_unknown := err.(Unknown_Variable)
  testing.expect(t, is_unknown)
}

@(test)
test_variable_name_accepts_plain_string_too :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `5 "x" ! "x" @`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(5))))
}
