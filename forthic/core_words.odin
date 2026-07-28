package forthic

core_module_create :: proc() -> ^Module {
  core_module := module_create("core")

  module_add_native_word(core_module, "+", native_plus, "( a:number b:number -- sum:number )", "Add two numbers", {})
  return core_module
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
