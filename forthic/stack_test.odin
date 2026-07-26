package forthic

import "core:testing"

@(test)
test_stack_new :: proc(t: ^testing.T) {
  stack: Stack
  defer stack_destroy(&stack)

  testing.expect(t, stack_is_empty(&stack))
  testing.expect_value(t, stack_len(&stack), 0)
}

@(test)
test_stack_push_pop :: proc(t: ^testing.T) {
  stack: Stack
  defer stack_destroy(&stack)

  stack_push(&stack, Forthic_Value(i64(42)))
  stack_push(&stack, Forthic_Value("hello"))

  testing.expect_value(t, stack_len(&stack), 2)

  top, top_err := stack_pop(&stack)
  testing.expect(t, top_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value("hello")))

  next, next_err := stack_pop(&stack)
  testing.expect(t, next_err == nil)
  testing.expect(t, forthic_value_equal(next, Forthic_Value(i64(42))))

  testing.expect(t, stack_is_empty(&stack))
}

@(test)
test_stack_pop_empty :: proc(t: ^testing.T) {
  stack: Stack
  defer stack_destroy(&stack)

  _, err := stack_pop(&stack)
  _, is_underflow := err.(Stack_Underflow)
  testing.expect(t, is_underflow)
}

@(test)
test_stack_peek :: proc(t: ^testing.T) {
  stack: Stack
  defer stack_destroy(&stack)

  _, ok := stack_peek(&stack)
  testing.expect(t, !ok)

  stack_push(&stack, Forthic_Value(i64(42)))

  top, top_ok := stack_peek(&stack)
  testing.expect(t, top_ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(42))))
  testing.expect_value(t, stack_len(&stack), 1) // Peek doesn't remove
}

@(test)
test_stack_clear :: proc(t: ^testing.T) {
  stack: Stack
  defer stack_destroy(&stack)

  stack_push(&stack, Forthic_Value(i64(1)))
  stack_push(&stack, Forthic_Value(i64(2)))
  stack_push(&stack, Forthic_Value(i64(3)))

  stack_clear(&stack)
  testing.expect(t, stack_is_empty(&stack))
}

@(test)
test_stack_get :: proc(t: ^testing.T) {
  stack: Stack
  defer stack_destroy(&stack)

  stack_push(&stack, Forthic_Value(i64(1)))
  stack_push(&stack, Forthic_Value(i64(2)))
  stack_push(&stack, Forthic_Value(i64(3)))

  v0, ok0 := stack_get(&stack, 0)
  testing.expect(t, ok0)
  testing.expect(t, forthic_value_equal(v0, Forthic_Value(i64(1))))

  v1, ok1 := stack_get(&stack, 1)
  testing.expect(t, ok1)
  testing.expect(t, forthic_value_equal(v1, Forthic_Value(i64(2))))

  v2, ok2 := stack_get(&stack, 2)
  testing.expect(t, ok2)
  testing.expect(t, forthic_value_equal(v2, Forthic_Value(i64(3))))

  _, ok3 := stack_get(&stack, 3)
  testing.expect(t, !ok3)
}

@(test)
test_stack_dup :: proc(t: ^testing.T) {
  stack: Stack
  defer stack_destroy(&stack)

  stack_push(&stack, Forthic_Value(i64(42)))

  dup := stack_dup(&stack)
  defer stack_destroy(&dup)

  testing.expect_value(t, stack_len(&stack), stack_len(&dup))

  popped, popped_err := stack_pop(&stack)
  testing.expect(t, popped_err == nil)

  dup_top, dup_ok := stack_peek(&dup)
  testing.expect(t, dup_ok)
  testing.expect(t, forthic_value_equal(popped, dup_top))
}
