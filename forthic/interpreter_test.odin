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
test_interpreter_record_key_with_no_value_is_error :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .a 1 .flag }")
  missing, is_missing := err.(Missing_Record_Value)
  testing.expect(t, is_missing)
  testing.expect_value(t, missing.key, "flag")
}

@(test)
test_interpreter_record_lone_key_is_error :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .flag }")
  _, is_missing := err.(Missing_Record_Value)
  testing.expect(t, is_missing)
}

// A Dot_Symbol reaching value position is an ordinary string, so this is a
// well-formed pair. Only an odd item count is an error.
@(test)
test_interpreter_record_dot_symbol_as_value :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .flag .other }")
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make(Record)
  defer delete(expected)
  expected["flag"] = Forthic_Value(string("other"))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

// A Dot_Symbol only exists so `}` can tell a key from a value. An element that
// lands in an array is an ordinary string, so it compares equal to one.
@(test)
test_interpreter_array_dot_symbol_element_is_string :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "[ .a .b ]")
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make([dynamic]Forthic_Value, 0, 2)
  defer delete(expected)
  append(&expected, Forthic_Value(string("a")))
  append(&expected, Forthic_Value(string("b")))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

// A close word with no opener used to pop an empty start-position stack, which
// aborted the process rather than reporting the syntax error.
@(test)
test_interpreter_unmatched_record_close_is_error :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "1 2 }")
  unmatched, is_unmatched := err.(Unmatched_Collection_Close)
  testing.expect(t, is_unmatched)
  testing.expect_value(t, unmatched.kind, Collection_Kind.Record)
}

@(test)
test_interpreter_unmatched_array_close_is_error :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "1 2 ]")
  unmatched, is_unmatched := err.(Unmatched_Collection_Close)
  testing.expect(t, is_unmatched)
  testing.expect_value(t, unmatched.kind, Collection_Kind.Array)
}

// `[` and `{` leave a Collection_Mark on the stack and `]`/`}` fold back to it.
// The mark is an ordinary Forthic value, which is what makes `[` a word rather
// than syntax: words can move it.
@(test)
test_interpreter_collection_mark_is_a_value_on_the_stack :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  // DUP copies the mark; the `]` closes the copy, leaving the original.
  err := run_forthic(&interp, "[ DUP 1 ]")
  testing.expect(t, err == nil)
  testing.expect_value(t, stack_len(&interp.stack), 2)

  bottom, got_bottom := stack_get(&interp.stack, 0)
  testing.expect(t, got_bottom)
  mark, is_mark := bottom.(Collection_Mark)
  testing.expect(t, is_mark)
  testing.expect_value(t, mark.kind, Collection_Kind.Array)
  testing.expect_value(t, mark.location.start.line, 1)
  testing.expect_value(t, mark.location.start.column, 1)
}

// A mark on the stack should not read as the string "[".
@(test)
test_interpreter_collection_mark_renders_as_a_mark :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "[ DUP 1 ]")
  testing.expect(t, err == nil)

  bottom, _ := stack_get(&interp.stack, 0)
  testing.expect_value(t, forthic_value_to_string(bottom), "<[>")
}

// The payoff of the mark being a value: moving it changes what the literal
// captures.
@(test)
test_interpreter_swap_moves_the_mark_into_the_array :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "1 [ SWAP ]")
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make([dynamic]Forthic_Value, 0, 1)
  defer delete(expected)
  append(&expected, Forthic_Value(i64(1)))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

@(test)
test_interpreter_open_bracket_factors_into_a_definition :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, ": MARK   [ ;   MARK 1 2 ]")
  testing.expect(t, err == nil)

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)

  expected := make([dynamic]Forthic_Value, 0, 2)
  defer delete(expected)
  append(&expected, Forthic_Value(i64(1)))
  append(&expected, Forthic_Value(i64(2)))

  testing.expect(t, forthic_value_equal(top, Forthic_Value(expected)))
}

// Under the old stack-depth model this silently produced an empty array: DROP
// reached below the recorded depth, so the count came out zero and `3` -- pushed
// inside the literal -- was left out with nothing reported. Popping to a mark
// cannot step over the opener that way.
@(test)
test_interpreter_dropping_the_mark_leaves_nothing_to_close :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "1 2 [ DROP 3 ]")
  unmatched, is_unmatched := err.(Unmatched_Collection_Close)
  testing.expect(t, is_unmatched)
  testing.expect_value(t, unmatched.kind, Collection_Kind.Array)
}

// The mark carries the opener's location, so the error points at the `[` that
// was left unclosed rather than the `}` that tripped over it.
@(test)
test_interpreter_mismatch_reports_the_unclosed_opener_location :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .a [ .b 1 }")
  mismatch, is_mismatch := err.(Mismatched_Collection)
  testing.expect(t, is_mismatch)
  // The `[` is at column 6, not the `}` at column 13.
  testing.expect_value(t, mismatch.location.start.line, 1)
  testing.expect_value(t, mismatch.location.start.column, 6)
}

// A close word matches only its own opener, so the other one is not a delimiter
// to it: left unchecked it is folded into the collection as an ordinary item,
// and at an even item count the key/value rule sees nothing wrong either. The
// failure mode is a wrong value rather than an error, so both directions are
// pinned.
@(test)
test_interpreter_record_close_reaching_open_array_is_error :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .a [ .b 1 }")
  mismatch, is_mismatch := err.(Mismatched_Collection)
  testing.expect(t, is_mismatch)
  testing.expect_value(t, mismatch.expected, Collection_Kind.Record)
  testing.expect_value(t, mismatch.got, Collection_Kind.Array)
}

@(test)
test_interpreter_array_close_reaching_open_record_is_error :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "[ .a { 1 2 ]")
  mismatch, is_mismatch := err.(Mismatched_Collection)
  testing.expect(t, is_mismatch)
  testing.expect_value(t, mismatch.expected, Collection_Kind.Array)
  testing.expect_value(t, mismatch.got, Collection_Kind.Record)
}

// Errors reach the user through fmt.println, so a bare struct names the two
// kinds but not the fix. The note names the delimiter that has to be added.
@(test)
test_interpreter_mismatched_collection_note_names_missing_delimiter :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  err := run_forthic(&interp, "{ .a [ .b 1 }")
  mismatch, is_mismatch := err.(Mismatched_Collection)
  testing.expect(t, is_mismatch)
  testing.expect_value(
    t,
    mismatch.note,
    "Mismatched '}' -- an unclosed '[' is open inside this '{'. Add the ']' it needs",
  )
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
