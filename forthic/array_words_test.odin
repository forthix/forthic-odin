package forthic

import "core:testing"

@(test)
test_length_of_array_and_record :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ 1 2 3 ] LENGTH { .a 1 .b 2 } LENGTH`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 2)

  a, _ := stack_get(&interp.stack, 0)
  b, _ := stack_get(&interp.stack, 1)
  testing.expect(t, forthic_value_equal(a, Forthic_Value(i64(3))))
  testing.expect(t, forthic_value_equal(b, Forthic_Value(i64(2))))
}

@(test)
test_nth_returns_element_or_nil :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ 10 20 30 ] 1 NTH`)
  testing.expect(t, err == nil)
  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(20))))

  err = run_forthic(&interp, `[ 10 20 30 ] 99 NTH`)
  testing.expect(t, err == nil)
  top2, pop_err2 := stack_pop(&interp.stack)
  testing.expect(t, pop_err2 == nil)
  testing.expect(t, top2 == nil)
}

@(test)
test_map_transforms_each_item :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ 1 2 3 ] "2 *" MAP`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  result, is_array := top.([dynamic]Forthic_Value)
  testing.expect(t, is_array)
  testing.expect_value(t, len(result), 3)
  testing.expect(t, forthic_value_equal(result[0], Forthic_Value(i64(2))))
  testing.expect(t, forthic_value_equal(result[1], Forthic_Value(i64(4))))
  testing.expect(t, forthic_value_equal(result[2], Forthic_Value(i64(6))))
}

@(test)
test_map_with_key_exposes_index :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  // With with_key, each iteration sees (index item) on the stack, item on
  // top. SWAP brings index back on top so "10 * +" computes index*10 + item.
  err := run_forthic(&interp, `[ 5 6 7 ] "SWAP 10 * +" { .with_key TRUE } ~> MAP`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  result, is_array := top.([dynamic]Forthic_Value)
  testing.expect(t, is_array)
  testing.expect_value(t, len(result), 3)
  testing.expect(t, forthic_value_equal(result[0], Forthic_Value(i64(5))))  // 0*10 + 5
  testing.expect(t, forthic_value_equal(result[1], Forthic_Value(i64(16)))) // 1*10 + 6
  testing.expect(t, forthic_value_equal(result[2], Forthic_Value(i64(27)))) // 2*10 + 7
}

@(test)
test_map_empty_array_is_noop :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ ] "2 *" MAP`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  result, is_array := top.([dynamic]Forthic_Value)
  testing.expect(t, is_array)
  testing.expect_value(t, len(result), 0)
}

@(test)
test_foreach_runs_for_each_item_with_no_result :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ .total ] VARIABLES 0 .total ! [ 1 2 3 ] "( .n ! ) .total @ .n @ + .total !" FOREACH .total @`)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(6))))
  testing.expect_value(t, stack_len(&interp.stack), 0)
}

@(test)
test_foreach_with_key_exposes_index :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  // Sum of index*10 + item across all 3 proves both order and 0-based index:
  // (0*10+5) + (1*10+6) + (2*10+7) = 5 + 16 + 27 = 48.
  err := run_forthic(&interp, `
    [ .total ] VARIABLES 0 .total !
    [ 5 6 7 ] "( .item ! .index ! ) .total @ .index @ 10 * .item @ + + .total !" { .with_key TRUE } ~> FOREACH
    .total @
  `)
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(48))))
}

@(test)
test_foreach_empty_array_is_noop :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, `[ ] "PRINT" FOREACH`)
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 0)
}
