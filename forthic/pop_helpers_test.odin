package forthic

import "core:testing"
import "core:mem/virtual"

@(test)
test_pop_string_ok_and_type_mismatch :: proc(t: ^testing.T) {
  arena: virtual.Arena
  _ = virtual.arena_init_growing(&arena)
  defer virtual.arena_destroy(&arena)
  context.allocator = virtual.arena_allocator(&arena)

  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  stack_push(&interp.stack, Forthic_Value(string("hi")))
  s, err := pop_string(&interp, "TEST")
  testing.expect(t, err == nil)
  testing.expect_value(t, s, "hi")

  stack_push(&interp.stack, Forthic_Value(i64(5)))
  _, err2 := pop_string(&interp, "TEST")
  _, is_mismatch := err2.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}

@(test)
test_pop_array_ok_and_type_mismatch :: proc(t: ^testing.T) {
  arena: virtual.Arena
  _ = virtual.arena_init_growing(&arena)
  defer virtual.arena_destroy(&arena)
  context.allocator = virtual.arena_allocator(&arena)

  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ 1 2 3 ]`)
  testing.expect(t, err == nil)
  arr, pop_err := pop_array(&interp, "TEST")
  testing.expect(t, pop_err == nil)
  testing.expect_value(t, len(arr), 3)

  stack_push(&interp.stack, Forthic_Value(string("not an array")))
  _, err2 := pop_array(&interp, "TEST")
  _, is_mismatch := err2.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}
