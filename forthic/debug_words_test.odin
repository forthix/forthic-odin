package forthic

import "core:testing"

@(test)
test_print_pops_and_returns_no_error :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `"hi" PRINT`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 0)
}
