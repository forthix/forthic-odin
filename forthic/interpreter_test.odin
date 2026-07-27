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
