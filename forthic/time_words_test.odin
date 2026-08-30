package forthic

import "core:testing"

@(test)
test_now_ms_returns_a_positive_int :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `NOW-MS`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  ms, is_int := top.(i64)
  testing.expect(t, is_int)
  testing.expect(t, ms > 0)
}
