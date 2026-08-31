package forthic

import "core:testing"
import "core:os"
import "core:fmt"

@(private)
write_temp_forthic_file :: proc(t: ^testing.T, name: string, contents: string) -> string {
  dir, dir_err := os.temp_dir(context.allocator)
  testing.expect(t, dir_err == nil)
  defer delete(dir)

  path := fmt.tprintf("%s/load_object_test_%s.forthic", dir, name)
  write_err := os.write_entire_file(path, transmute([]byte)contents)
  testing.expect(t, write_err == nil)
  return path
}

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
test_load_object_returns_the_files_one_value :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  path := write_temp_forthic_file(t, "one_value", `{ .a 1 .b 2 }`)
  defer os.remove(path)

  err := run_forthic(&interp, fmt.tprintf(`"%s" LOAD-OBJECT`, path))
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  record, is_record := top.(Record)
  testing.expect(t, is_record)
  testing.expect(t, forthic_value_equal(record[Dot_Symbol("a")], Forthic_Value(i64(1))))
  testing.expect(t, forthic_value_equal(record[Dot_Symbol("b")], Forthic_Value(i64(2))))
}

@(test)
test_load_object_errors_if_file_leaves_no_value :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  path := write_temp_forthic_file(t, "zero_values", `1 DROP`)
  defer os.remove(path)

  err := run_forthic(&interp, fmt.tprintf(`"%s" LOAD-OBJECT`, path))
  _, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}

@(test)
test_load_object_errors_if_file_leaves_multiple_values :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  path := write_temp_forthic_file(t, "two_values", `1 2`)
  defer os.remove(path)

  err := run_forthic(&interp, fmt.tprintf(`"%s" LOAD-OBJECT`, path))
  _, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}

@(test)
test_load_object_does_not_corrupt_callers_stack_on_error :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  path := write_temp_forthic_file(t, "sentinel_check", `1 2`)
  defer os.remove(path)

  err := run_forthic(&interp, fmt.tprintf(`99 "%s" LOAD-OBJECT`, path))
  _, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)

  testing.expect_value(t, stack_len(&interp.stack), 1)
  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(99))))
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
