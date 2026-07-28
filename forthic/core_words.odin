package forthic

core_module_create :: proc() -> ^Module {
  core_module := module_create("core")

  module_add_native_word(core_module, "+", native_plus, "( a:number b:number -- sum:number )", "Add two numbers", {})
  module_add_native_word(core_module, "DUP", native_dup, "( a -- a a )", "Duplicate top of stack", {"5 DUP  # => 5 5"})
  module_add_native_word(core_module, "SWAP", native_swap, "( a b -- b a )", "Swap the top two stack items", {"1 2 SWAP  # => 2 1"})

  return core_module
}

native_dup :: proc(interp: ^Interpreter) -> Error {
  top, ok := stack_peek(&interp.stack)
  if !ok {
    return Stack_Underflow{}
  }
  stack_push(&interp.stack, top)
  return nil
}

native_swap :: proc(interp: ^Interpreter) -> Error {
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

native_plus :: proc(interp: ^Interpreter) -> Error {
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
    stack_push(&interp.stack, Forthic_Value(l_int + r_int))
    return nil
  }

  l_float, l_ok := forthic_value_as_f64(l_val)
  r_float, r_ok := forthic_value_as_f64(r_val)
  if !l_ok || !r_ok {
    return Type_Mismatch{note = "+ requires two numbers", location = Code_Location{}}
  }

  stack_push(&interp.stack, Forthic_Value(l_float + r_float))
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
