package forthic

import "core:time"

builtin_now_ms :: proc(interp: ^Interpreter) -> Error {
  ms := time.to_unix_nanoseconds(time.now()) / 1_000_000
  stack_push(&interp.stack, Forthic_Value(i64(ms)))
  return nil
}
