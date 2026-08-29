package forthic

import "core:testing"

@(test)
test_jq_at_looks_up_bare_field_by_dot_symbol :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `{ .E 1 .W -1 } .E JQ@`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(1))))
}

@(test)
test_jq_at_drills_through_path_array :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `{ .a { .b [ 10 20 30 ] } } [ .a .b 1 ] JQ@`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(20))))
}

@(test)
test_jq_at_missing_field_is_nil :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `{ .E 1 } .N JQ@`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, top == nil)
}

@(test)
test_jq_at_non_container_is_nil :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `5 .N JQ@`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, top == nil)
}
