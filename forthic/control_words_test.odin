package forthic

import "core:testing"

@(test)
test_run_executes_forthic_string :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `"1 2 +" RUN`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(3))))
}

@(test)
test_times_run_runs_n_times :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ .n ] VARIABLES 0 .n ! 5 "1 .n @ + .n !" TIMES-RUN .n @`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(5))))
}

@(test)
test_times_run_zero_times_is_noop :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `0 "99" TIMES-RUN`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 0)
}

@(test)
test_if_selects_branch_by_value :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `TRUE 1 2 IF`)
  testing.expect(t, err == nil)
  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(1))))

  err = run_forthic(&interp, `FALSE 1 2 IF`)
  testing.expect(t, err == nil)
  top2, pop_err2 := stack_pop(&interp.stack)
  testing.expect(t, pop_err2 == nil)
  testing.expect(t, forthic_value_equal(top2, Forthic_Value(i64(2))))
}

@(test)
test_if_run_runs_selected_branch :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `TRUE "1 1 +" "99" IF-RUN`)
  testing.expect(t, err == nil)
  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(2))))

  err = run_forthic(&interp, `FALSE "1 1 +" "99" IF-RUN`)
  testing.expect(t, err == nil)
  top2, pop_err2 := stack_pop(&interp.stack)
  testing.expect(t, pop_err2 == nil)
  testing.expect(t, forthic_value_equal(top2, Forthic_Value(i64(99))))
}

@(test)
test_when_runs_only_if_true :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `TRUE "1 1 +" WHEN`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 1)
  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(2))))

  err = run_forthic(&interp, `FALSE "1 1 +" WHEN`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 0)
}
