package forthic

import "core:testing"

@(private)
run_forthic :: proc(interp: ^Interpreter, forthic: string) -> Error {
  positioned_forthic := Positioned_Forthic{forthic = forthic, location = nil}
  return interpreter_run(interp, positioned_forthic)
}

@(test)
test_interpreter_missing_semicolon :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, ": UNCLOSED 42")
  _, is_missing := err.(Missing_Semicolon)
  testing.expect(t, is_missing)
}

@(test)
test_interpreter_nested_definition_missing_semicolon :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, ": A : B ;")
  _, is_missing := err.(Missing_Semicolon)
  testing.expect(t, is_missing)
}

@(test)
test_interpreter_extra_semicolon :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "42 ;")
  _, is_extra := err.(Extra_Semicolon)
  testing.expect(t, is_extra)
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

@(test)
test_interpreter_subtract :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "5 3 -")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(2))))
}

@(test)
test_interpreter_multiply :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "4 3 *")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(12))))
}

@(test)
test_interpreter_divide_exact :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "6 3 /")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(2))))
}

@(test)
test_interpreter_divide_fractional :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "7 2 /")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(f64(3.5))))
}

@(test)
test_interpreter_divide_by_zero :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "5 0 /")
  _, is_div_by_zero := err.(Division_By_Zero)
  testing.expect(t, is_div_by_zero)
}

@(test)
test_interpreter_add_type_mismatch :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "\"a\" 3 +")
  mismatch, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
  testing.expect_value(t, mismatch.note, "+ requires two numbers")
}

@(test)
test_interpreter_drop :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "1 2 DROP")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, top_err := stack_pop(&interp.stack)
  testing.expect(t, top_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(1))))
}

@(test)
test_interpreter_drop_empty_stack :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "DROP")
  _, is_underflow := err.(Stack_Underflow)
  testing.expect(t, is_underflow)
}

@(test)
test_interpreter_dup :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "5 DUP")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 2)

  top, top_err := stack_pop(&interp.stack)
  testing.expect(t, top_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(5))))

  second, second_err := stack_pop(&interp.stack)
  testing.expect(t, second_err == nil)
  testing.expect(t, forthic_value_equal(second, Forthic_Value(i64(5))))
}

@(test)
test_interpreter_swap :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "1 2 SWAP")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 2)

  top, top_err := stack_pop(&interp.stack)
  testing.expect(t, top_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(1))))

  second, second_err := stack_pop(&interp.stack)
  testing.expect(t, second_err == nil)
  testing.expect(t, forthic_value_equal(second, Forthic_Value(i64(2))))
}

@(test)
test_interpreter_simple_definition :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err1 := run_forthic(&interp, ": FORTY-TWO 42 ;")
  testing.expect(t, err1 == nil)

  err2 := run_forthic(&interp, "FORTY-TWO")
  testing.expect(t, err2 == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(42))))
}

@(test)
test_interpreter_definition_with_multiple_values :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err1 := run_forthic(&interp, ": NUMS 1 2 3 ;")
  testing.expect(t, err1 == nil)

  err2 := run_forthic(&interp, "NUMS")
  testing.expect(t, err2 == nil)

  testing.expect_value(t, stack_len(&interp.stack), 3)

  v3, err3 := stack_pop(&interp.stack)
  testing.expect(t, err3 == nil)
  testing.expect(t, forthic_value_equal(v3, Forthic_Value(i64(3))))

  v2, err_v2 := stack_pop(&interp.stack)
  testing.expect(t, err_v2 == nil)
  testing.expect(t, forthic_value_equal(v2, Forthic_Value(i64(2))))

  v1, err_v1 := stack_pop(&interp.stack)
  testing.expect(t, err_v1 == nil)
  testing.expect(t, forthic_value_equal(v1, Forthic_Value(i64(1))))
}

@(test)
test_interpreter_array :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "[ 1 2 3 ]")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected: [dynamic]Forthic_Value
  defer delete(expected)
  append(&expected, Forthic_Value(i64(1)))
  append(&expected, Forthic_Value(i64(2)))
  append(&expected, Forthic_Value(i64(3)))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

@(test)
test_interpreter_word_doc :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  forthic := "#: Adds two to a number.\n#: @effect ( n -- n+2 )\n#: @example 5 PLUS-TWO  # => 7\n: PLUS-TWO 2 + ;"
  err := run_forthic(&interp, forthic)
  testing.expect(t, err == nil)

  app_module := interp.module_stack[0]
  word, found := module_find_word(app_module, "PLUS-TWO")
  testing.expect(t, found)

  doc, has_doc := word.doc.?
  testing.expect(t, has_doc)
  testing.expect_value(t, doc.description, "Adds two to a number.")
  testing.expect_value(t, doc.stack_effect, "( n -- n+2 )")
  testing.expect_value(t, len(doc.examples), 1)
  testing.expect_value(t, doc.examples[0], "5 PLUS-TWO  # => 7")
}

@(test)
test_interpreter_module_creates_submodule :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "\"raylib\" MODULE")
  testing.expect(t, err == nil)

  testing.expect_value(t, len(interp.module_stack), 2)

  app_module := interp.module_stack[0]
  top_module := interp.module_stack[1]
  testing.expect_value(t, top_module.name, "raylib")
  testing.expect(t, top_module == app_module.submodules["raylib"])
}

@(test)
test_interpreter_module_end_module :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "\"raylib\" MODULE END-MODULE")
  testing.expect(t, err == nil)

  testing.expect_value(t, len(interp.module_stack), 1)
  testing.expect(t, interp.module_stack[0] == interp.module_stack[len(interp.module_stack) - 1])
}

@(test)
test_interpreter_module_scopes_definition :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "\"raylib\" MODULE : GREET \"hi\" ; END-MODULE")
  testing.expect(t, err == nil)

  app_module := interp.module_stack[0]
  raylib_module := app_module.submodules["raylib"]

  _, found_in_app := module_find_word(app_module, "GREET")
  testing.expect(t, !found_in_app)

  _, found_in_raylib := module_find_word(raylib_module, "GREET")
  testing.expect(t, found_in_raylib)
}

@(test)
test_interpreter_module_requires_string_name :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "42 MODULE")
  _, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}

@(test)
test_interpreter_module_empty_stack :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "MODULE")
  _, is_underflow := err.(Stack_Underflow)
  testing.expect(t, is_underflow)
}

@(test)
test_interpreter_app_module :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "\"raylib\" MODULE APP-MODULE")
  testing.expect(t, err == nil)

  testing.expect_value(t, len(interp.module_stack), 3)
  testing.expect(t, interp.module_stack[2] == interp.module_stack[0])

  err2 := run_forthic(&interp, "END-MODULE")
  testing.expect(t, err2 == nil)
  testing.expect_value(t, len(interp.module_stack), 2)
  testing.expect_value(t, interp.module_stack[1].name, "raylib")
}

@(test)
test_interpreter_end_module_extra :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "END-MODULE")
  _, is_extra := err.(Extra_End_Module)
  testing.expect(t, is_extra)
}

@(test)
test_interpreter_module_reopen_reuses_submodule :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err1 := run_forthic(&interp, "\"raylib\" MODULE : GREET \"hi\" ; END-MODULE")
  testing.expect(t, err1 == nil)

  err2 := run_forthic(&interp, "\"raylib\" MODULE")
  testing.expect(t, err2 == nil)

  reopened_module := interp.module_stack[len(interp.module_stack) - 1]
  _, found := module_find_word(reopened_module, "GREET")
  testing.expect(t, found)
}

@(test)
test_interpreter_bool_literal_true :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "TRUE")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(bool(true))))
}

@(test)
test_interpreter_bool_literal_false :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "FALSE")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(bool(false))))
}

@(test)
test_interpreter_float_literal :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "3.14")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(f64(3.14))))
}

@(test)
test_interpreter_negative_int_literal :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "-10")
  testing.expect(t, err == nil)

  top, ok := stack_peek(&interp.stack)
  testing.expect(t, ok)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(-10))))
}

@(test)
test_interpreter_literal_inside_definition_not_pushed_early :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err1 := run_forthic(&interp, ": PI 3.14 ;")
  testing.expect(t, err1 == nil)

  // Defining the word must not push its literal onto the stack.
  testing.expect_value(t, stack_len(&interp.stack), 0)

  err2 := run_forthic(&interp, "PI PI")
  testing.expect(t, err2 == nil)

  testing.expect_value(t, stack_len(&interp.stack), 2)

  v2, err_v2 := stack_pop(&interp.stack)
  testing.expect(t, err_v2 == nil)
  testing.expect(t, forthic_value_equal(v2, Forthic_Value(f64(3.14))))

  v1, err_v1 := stack_pop(&interp.stack)
  testing.expect(t, err_v1 == nil)
  testing.expect(t, forthic_value_equal(v1, Forthic_Value(f64(3.14))))
}

@(test)
test_interpreter_to_options_sets_pending_word_options :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .width 800 } ~>")
  testing.expect(t, err == nil)

  options, has_options := interp.pending_word_options.?
  testing.expect(t, has_options)
  testing.expect_value(t, record_get_int(Record(options), "width", 0), i64(800))
}

@(test)
test_interpreter_to_options_requires_record :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "42 ~>")
  _, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}

@(test)
test_interpreter_to_options_empty_stack :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "~>")
  _, is_underflow := err.(Stack_Underflow)
  testing.expect(t, is_underflow)
}

@(test)
test_interpreter_pending_word_options_cleared_after_next_word :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "5 { .width 800 } ~> DUP")
  testing.expect(t, err == nil)

  _, has_options := interp.pending_word_options.?
  testing.expect(t, !has_options)
}

@(test)
test_interpreter_record_bare_flag_at_end :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .a 1 .flag }")
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make(Record)
  defer delete(expected)
  expected["a"] = Forthic_Value(i64(1))
  expected["flag"] = Forthic_Value(bool(true))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

@(test)
test_interpreter_record_consecutive_bare_flags :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .flag .other }")
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make(Record)
  defer delete(expected)
  expected["flag"] = Forthic_Value(bool(true))
  expected["other"] = Forthic_Value(bool(true))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

@(test)
test_interpreter_record_all_bare_flags :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .flag }")
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make(Record)
  defer delete(expected)
  expected["flag"] = Forthic_Value(bool(true))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

@(test)
test_interpreter_record_key_must_be_dot_symbol :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ \"not-a-key\" 5 }")
  _, is_mismatch := err.(Type_Mismatch)
  testing.expect(t, is_mismatch)
}

@(test)
test_interpreter_record :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .name \"Player One\" .score 100 }")
  testing.expect(t, err == nil)

  testing.expect_value(t, stack_len(&interp.stack), 1)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make(Record)
  defer delete(expected)
  expected["name"] = Forthic_Value(string("Player One"))
  expected["score"] = Forthic_Value(i64(100))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}
