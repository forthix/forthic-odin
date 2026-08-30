package forthic

// A variable's name can be given as a Dot_Symbol (idiomatic, e.g. .player-x)
// or a plain string.
variable_name_from_value :: proc(value: Forthic_Value) -> (string, bool) {
  #partial switch v in value {
  case Dot_Symbol:
    return string(v), true
  case string:
    return v, true
  case:
    return "", false
  }
}

// ( names:array -- )
builtin_variables :: proc(interp: ^Interpreter) -> Error {
  names, err := pop_array(interp, "VARIABLES")
  if err != nil {
    return err
  }

  module := interp.module_stack[len(interp.module_stack) - 1]
  for name_value in names {
    name, ok := variable_name_from_value(name_value)
    if !ok {
      return Type_Mismatch{note = "VARIABLES requires an array of variable names"}
    }
    if _, declared := module.variables[name]; !declared {
      module.variables[name] = nil
    }
  }
  return nil
}

// ( value name -- )
builtin_set_variable :: proc(interp: ^Interpreter) -> Error {
  name_str, name_err := pop_name(interp, "!")
  if name_err != nil {
    return name_err
  }
  value, value_err := stack_pop(&interp.stack)
  if value_err != nil {
    return value_err
  }

  module := interp.module_stack[len(interp.module_stack) - 1]
  module.variables[name_str] = value
  return nil
}

// ( name -- value )
builtin_get_variable :: proc(interp: ^Interpreter) -> Error {
  name_str, err := pop_name(interp, "@")
  if err != nil {
    return err
  }

  module := interp.module_stack[len(interp.module_stack) - 1]
  value, declared := module.variables[name_str]
  if !declared {
    return Unknown_Variable{name = name_str}
  }

  stack_push(&interp.stack, value)
  return nil
}

// ( value name -- value )
builtin_set_and_get_variable :: proc(interp: ^Interpreter) -> Error {
  name_str, name_err := pop_name(interp, "!@")
  if name_err != nil {
    return name_err
  }
  value, value_err := stack_pop(&interp.stack)
  if value_err != nil {
    return value_err
  }

  module := interp.module_stack[len(interp.module_stack) - 1]
  module.variables[name_str] = value
  stack_push(&interp.stack, value)
  return nil
}
