package forthic

core_module_create :: proc() -> ^Module {
  core_module := module_create("core")

  module_add_builtin_word(core_module, "~>", builtin_set_options, "( options -- )", "Sets pending word options", {})

  module_add_builtin_word(core_module, "DROP", builtin_drop, "( a -- )", "Drops top of stack", {})
  module_add_builtin_word(core_module, "DUP", builtin_dup, "( a -- a a )", "Duplicate top of stack", {"5 DUP  # => 5 5"})
  module_add_builtin_word(core_module, "SWAP", builtin_swap, "( a b -- b a )", "Swap the top two stack items", {"1 2 SWAP  # => 2 1"})

  module_add_builtin_word(core_module, "+", builtin_add, "( a:number b:number -- sum:number )", "Add two numbers", {})
  module_add_builtin_word(core_module, "-", builtin_subtract, "( a:number b:number -- difference:number )", "Subtracts two numbers", {})
  module_add_builtin_word(core_module, "*", builtin_multiply, "( a:number b:number -- product:number )", "Multiplies two numbers", {})
  module_add_builtin_word(core_module, "/", builtin_divide, "( a:number b:number -- quotient:number )", "Divides two numbers", {})

  module_add_builtin_word(core_module, "MODULE", builtin_module, "( module_name:string -- )", "Find or create submodule in current module and make it the current module", {})
  module_add_builtin_word(core_module, "END-MODULE", builtin_end_module, "( -- )", "Pop the current module from the module stack", {})
  module_add_builtin_word(core_module, "APP-MODULE", builtin_app_module, "( -- )", "Make the application module the current module", {})

  return core_module
}

builtin_drop :: proc(interp: ^Interpreter) -> Error {
  _, err := stack_pop(&interp.stack)
  return err
}

builtin_dup :: proc(interp: ^Interpreter) -> Error {
  top, ok := stack_peek(&interp.stack)
  if !ok {
    return Stack_Underflow{}
  }
  stack_push(&interp.stack, top)
  return nil
}

builtin_swap :: proc(interp: ^Interpreter) -> Error {
  b_val, b_err := stack_pop(&interp.stack)
  if b_err != nil {
    return b_err
  }

  a_val, a_err := stack_pop(&interp.stack)
  if a_err != nil {
    return a_err
  }

  stack_push(&interp.stack, b_val)
  stack_push(&interp.stack, a_val)
  return nil
}

builtin_add :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_numeric_op(interp, "+ requires two numbers",
    proc(a, b: i64) -> i64 { return a + b },
    proc(a, b: f64) -> f64 { return a + b },
  )
}


builtin_subtract :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_numeric_op(interp, "- requires two numbers",
    proc(a, b: i64) -> i64 { return a - b },
    proc(a, b: f64) -> f64 { return a - b },
  )
}

builtin_multiply :: proc(interp: ^Interpreter) -> Error {
  return builtin_binary_numeric_op(interp, "* requires two numbers",
    proc(a, b: i64) -> i64 { return a * b },
    proc(a, b: f64) -> f64 { return a * b },
  )
}

builtin_divide :: proc(interp: ^Interpreter) -> Error {
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
    return Type_Mismatch{note = "/ requires two numbers", location = Code_Location{}}
  }
  if r_float == 0 {
    return Division_By_Zero{location = Code_Location{}}
  }

  stack_push(&interp.stack, forthic_value_from_f64(l_float / r_float))
  return nil
}

// ----------------------------------------------------------------------------
// Support
// ----------------------------------------------------------------------------


builtin_binary_numeric_op :: proc(
  interp: ^Interpreter,
  note: string,
  int_op: proc(a, b: i64) -> i64,
  float_op: proc(a, b: f64) -> f64,
  ) -> Error {
  r_val, r_error := stack_pop(&interp.stack)
  if r_error != nil {
    return r_error
  }

  l_val, l_error := stack_pop(&interp.stack)
  if l_error != nil {
    return l_error
  }

  l_int, l_is_int := l_val.(i64)
  r_int, r_is_int := r_val.(i64)
  if l_is_int && r_is_int {
    stack_push(&interp.stack, Forthic_Value(int_op(l_int, r_int)))
    return nil
  }

  l_float, l_ok := forthic_value_as_f64(l_val)
  r_float, r_ok := forthic_value_as_f64(r_val)
  if !l_ok || !r_ok {
    return Type_Mismatch{note = note, location = Code_Location{}}
  }

  stack_push(&interp.stack, Forthic_Value(float_op(l_float, r_float)))
  return nil
}

forthic_value_as_f64 :: proc(v: Forthic_Value) -> (f64, bool) {
  #partial switch x in v {
  case i64:
    return f64(x), true
  case f64:
    return x, true
  case:
    return 0, false
  }
  return 0, false
}

forthic_value_from_f64 :: proc(num: f64) -> Forthic_Value {
  as_int := i64(num)
  if f64(as_int) == num {
    return Forthic_Value(as_int)
  }
  return Forthic_Value(num)
}
