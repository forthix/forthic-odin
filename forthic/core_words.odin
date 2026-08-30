package forthic

core_module_create :: proc() -> ^Module {
  core_module := module_create("core")

  module_add_builtin_word(core_module, "~>", builtin_set_options, "( options -- )", "Sets pending word options", {})
  module_add_builtin_word(core_module, "PRINT", builtin_print, "( a -- )", "Prints the top of stack to stdout, for debugging", {`"hi" PRINT`})
  module_add_builtin_word(core_module, "LENGTH", builtin_length, "( container -- length:int )", "Length of an array or record", {`[ 1 2 3 ] LENGTH  # => 3`})
  module_add_builtin_word(core_module, "NTH", builtin_nth, "( container:array n:int -- item )", "Gets the nth (0-indexed) element of an array; nil if out of range", {`[ 10 20 30 ] 1 NTH  # => 20`})
  module_add_builtin_word(core_module, "NOW-MS", builtin_now_ms, "( -- ms:int )", "Current Unix time in milliseconds", {"NOW-MS"})

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

  module_add_builtin_word(core_module, ">STR", builtin_to_str, "( item -- string )", "Converts a value to a string", {`5 >STR  # => "5"`})
  module_add_builtin_word(core_module, "CONCAT", builtin_concat, "( strings:array -- result:string )", "Concatenates an array of strings into one string", {`[ "a" "b" ] CONCAT  # => "ab"`})

  module_add_builtin_word(core_module, "JQ@", builtin_jq_at, "( container path -- value )", "Drills into a record/array by a path of dot-symbol/string fields and int indices; a bare (non-array) path is one segment. nil on any miss.", {`{ .E 1 .W -1 } .E JQ@  # => 1`})

  module_add_builtin_word(core_module, "VARIABLES", builtin_variables, "( names:array -- )", "Declares variables (by name) in the current module", {`[ .x .y ] VARIABLES`})
  module_add_builtin_word(core_module, "!", builtin_set_variable, "( value name -- )", "Sets a variable's value (name is a dot-symbol or string), declaring it first if needed", {`5 .x !`})
  module_add_builtin_word(core_module, "@", builtin_get_variable, "( name -- value )", "Gets a variable's value (name is a dot-symbol or string); errors if undeclared", {`.x @`})
  module_add_builtin_word(core_module, "!@", builtin_set_and_get_variable, "( value name -- value )", "Sets a variable and returns the value", {`5 .x !@`})

  module_add_builtin_word(core_module, "RUN", builtin_run, "( forthic:string -- ? )", "Runs a Forthic string in the current context", {`"1 2 +" RUN`})
  module_add_builtin_word(core_module, "TIMES-RUN", builtin_times_run, "( num_times:int forthic:string -- ? )", "Runs a Forthic string num_times; no per-iteration value is passed automatically", {`3 "1 +" TIMES-RUN`})
  module_add_builtin_word(core_module, "IF", builtin_if, "( bool then_value else_value -- chosen )", "Pushes then_value if bool is true, else else_value", {`TRUE 1 2 IF  # => 1`})
  module_add_builtin_word(core_module, "IF-RUN", builtin_if_run, "( bool then_forthic else_forthic -- ? )", "Runs then_forthic if bool is true, else else_forthic", {`TRUE "1" "2" IF-RUN  # => 1`})
  module_add_builtin_word(core_module, "WHEN", builtin_when, "( bool forthic -- ? )", "Runs forthic if bool is true, otherwise does nothing", {`TRUE "1 2 +" WHEN`})

  module_add_builtin_word(core_module, "==", builtin_equal, "( a b -- equal:bool )", "Tests equality", {})
  module_add_builtin_word(core_module, "!=", builtin_not_equal, "( a b -- not_equal:bool )", "Tests inequality", {})
  module_add_builtin_word(core_module, "<", builtin_less_than, "( a:number b:number -- less:bool )", "Less than", {})
  module_add_builtin_word(core_module, "<=", builtin_less_equal, "( a:number b:number -- less_equal:bool )", "Less than or equal", {})
  module_add_builtin_word(core_module, ">", builtin_greater_than, "( a:number b:number -- greater:bool )", "Greater than", {})
  module_add_builtin_word(core_module, ">=", builtin_greater_equal, "( a:number b:number -- greater_equal:bool )", "Greater than or equal", {})
  module_add_builtin_word(core_module, "NOT", builtin_not, "( bool -- result:bool )", "Logical NOT", {})
  module_add_builtin_word(core_module, "AND", builtin_and, "( a:bool b:bool -- result:bool )", "Logical AND", {})
  module_add_builtin_word(core_module, "OR", builtin_or, "( a:bool b:bool -- result:bool )", "Logical OR", {})

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
