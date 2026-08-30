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

@(test)
test_undeclared_variable_set_inside_word_is_local_to_that_call :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `: SET-LOCAL   42 .tmp ! ; SET-LOCAL`)
  testing.expect(t, err == nil)

  get_err := run_forthic(&interp, `.tmp @`)
  _, is_unknown := get_err.(Unknown_Variable)
  testing.expect(t, is_unknown)
}

@(test)
test_nested_calls_do_not_clobber_each_others_locals :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `
    : INNER   99 .tmp ! .tmp @ ;
    : OUTER   1 .tmp ! INNER DROP .tmp @ ;
    OUTER
  `)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(1))))
}

@(test)
test_run_string_shares_callers_local_frame :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `
    : USES-RUN   7 .tmp ! ".tmp @" RUN ;
    USES-RUN
  `)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(7))))
}

@(test)
test_variables_declared_name_stays_shared_across_calls :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `
    [ .shared ] VARIABLES
    : SET-SHARED   5 .shared ! ;
    : GET-SHARED   .shared @ ;
    SET-SHARED
    GET-SHARED
  `)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(5))))
}
