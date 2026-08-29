package forthic

builtin_equal :: proc(interp: ^Interpreter) -> Error {
  b, b_err := stack_pop(&interp.stack)
  if b_err != nil {
    return b_err
  }
  a, a_err := stack_pop(&interp.stack)
  if a_err != nil {
    return a_err
  }
  stack_push(&interp.stack, Forthic_Value(forthic_value_equal(a, b)))
  return nil
}

builtin_not_equal :: proc(interp: ^Interpreter) -> Error {
  b, b_err := stack_pop(&interp.stack)
  if b_err != nil {
    return b_err
  }
  a, a_err := stack_pop(&interp.stack)
  if a_err != nil {
    return a_err
  }
  stack_push(&interp.stack, Forthic_Value(!forthic_value_equal(a, b)))
  return nil
}

builtin_less_than :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_comparison_op(interp, "< requires two numbers",
    proc(a, b: f64) -> bool { return a < b },
  )
}

builtin_less_equal :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_comparison_op(interp, "<= requires two numbers",
    proc(a, b: f64) -> bool { return a <= b },
  )
}

builtin_greater_than :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_comparison_op(interp, "> requires two numbers",
    proc(a, b: f64) -> bool { return a > b },
  )
}

builtin_greater_equal :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_comparison_op(interp, ">= requires two numbers",
    proc(a, b: f64) -> bool { return a >= b },
  )
}

builtin_not :: proc(interp: ^Interpreter) -> Error {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return err
  }
  bool_value, is_bool := value.(bool)
  if !is_bool {
    return Type_Mismatch{note = "NOT requires a boolean"}
  }
  stack_push(&interp.stack, Forthic_Value(!bool_value))
  return nil
}

builtin_and :: proc(interp: ^Interpreter) -> Error {
  b, b_err := stack_pop(&interp.stack)
  if b_err != nil {
    return b_err
  }
  a, a_err := stack_pop(&interp.stack)
  if a_err != nil {
    return a_err
  }
  a_bool, a_is_bool := a.(bool)
  b_bool, b_is_bool := b.(bool)
  if !a_is_bool || !b_is_bool {
    return Type_Mismatch{note = "AND requires two booleans"}
  }
  stack_push(&interp.stack, Forthic_Value(a_bool && b_bool))
  return nil
}

builtin_or :: proc(interp: ^Interpreter) -> Error {
  b, b_err := stack_pop(&interp.stack)
  if b_err != nil {
    return b_err
  }
  a, a_err := stack_pop(&interp.stack)
  if a_err != nil {
    return a_err
  }
  a_bool, a_is_bool := a.(bool)
  b_bool, b_is_bool := b.(bool)
  if !a_is_bool || !b_is_bool {
    return Type_Mismatch{note = "OR requires two booleans"}
  }
  stack_push(&interp.stack, Forthic_Value(a_bool || b_bool))
  return nil
}

// ----------------------------------------------------------------------------
// Support
// ----------------------------------------------------------------------------

builtin_binary_comparison_op :: proc(
  interp: ^Interpreter,
  note: string,
  compare: proc(a, b: f64) -> bool,
  ) -> Error {
  r_val, r_error := stack_pop(&interp.stack)
  if r_error != nil {
    return r_error
  }
  l_val, l_error := stack_pop(&interp.stack)
  if l_error != nil {
    return l_error
  }

  l_float, l_ok := forthic_value_as_f64(l_val)
  r_float, r_ok := forthic_value_as_f64(r_val)
  if !l_ok || !r_ok {
    return Type_Mismatch{note = note, location = Code_Location{}}
  }

  stack_push(&interp.stack, Forthic_Value(compare(l_float, r_float)))
  return nil
}
