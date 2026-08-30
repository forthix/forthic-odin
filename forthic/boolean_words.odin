package forthic

// ( a b -- equal:bool )
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

// ( a b -- not_equal:bool )
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

// ( a:number b:number -- less:bool )
builtin_less_than :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_comparison_op(interp, "< requires two numbers",
    proc(a, b: f64) -> bool { return a < b },
  )
}

// ( a:number b:number -- less_equal:bool )
builtin_less_equal :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_comparison_op(interp, "<= requires two numbers",
    proc(a, b: f64) -> bool { return a <= b },
  )
}

// ( a:number b:number -- greater:bool )
builtin_greater_than :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_comparison_op(interp, "> requires two numbers",
    proc(a, b: f64) -> bool { return a > b },
  )
}

// ( a:number b:number -- greater_equal:bool )
builtin_greater_equal :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_comparison_op(interp, ">= requires two numbers",
    proc(a, b: f64) -> bool { return a >= b },
  )
}

// ( bool -- result:bool )
builtin_not :: proc(interp: ^Interpreter) -> Error {
  bool_value, err := pop_bool(interp, "NOT")
  if err != nil {
    return err
  }
  stack_push(&interp.stack, Forthic_Value(!bool_value))
  return nil
}

// ( a:bool b:bool -- result:bool )
builtin_and :: proc(interp: ^Interpreter) -> Error {
  b_bool, b_err := pop_bool(interp, "AND")
  if b_err != nil {
    return b_err
  }
  a_bool, a_err := pop_bool(interp, "AND")
  if a_err != nil {
    return a_err
  }
  stack_push(&interp.stack, Forthic_Value(a_bool && b_bool))
  return nil
}

// ( a:bool b:bool -- result:bool )
builtin_or :: proc(interp: ^Interpreter) -> Error {
  b_bool, b_err := pop_bool(interp, "OR")
  if b_err != nil {
    return b_err
  }
  a_bool, a_err := pop_bool(interp, "OR")
  if a_err != nil {
    return a_err
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
