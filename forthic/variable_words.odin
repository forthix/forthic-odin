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

builtin_variables :: proc(interp: ^Interpreter) -> Error {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  names, is_array := value.([dynamic]Forthic_Value)
  if !is_array {
    return Type_Mismatch{note = "VARIABLES requires an array of variable names"}
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

builtin_set_variable :: proc(interp: ^Interpreter) -> Error {
  name, name_err := stack_pop(&interp.stack)
  if name_err != nil {
    return name_err
  }
  value, value_err := stack_pop(&interp.stack)
  if value_err != nil {
    return value_err
  }

  name_str, ok := variable_name_from_value(name)
  if !ok {
    return Type_Mismatch{note = "! requires a variable name"}
  }

  module := interp.module_stack[len(interp.module_stack) - 1]
  module.variables[name_str] = value
  return nil
}

builtin_get_variable :: proc(interp: ^Interpreter) -> Error {
  name, name_err := stack_pop(&interp.stack)
  if name_err != nil {
    return name_err
  }

  name_str, ok := variable_name_from_value(name)
  if !ok {
    return Type_Mismatch{note = "@ requires a variable name"}
  }

  module := interp.module_stack[len(interp.module_stack) - 1]
  value, declared := module.variables[name_str]
  if !declared {
    return Unknown_Variable{name = name_str}
  }

  stack_push(&interp.stack, value)
  return nil
}

builtin_set_and_get_variable :: proc(interp: ^Interpreter) -> Error {
  name, name_err := stack_pop(&interp.stack)
  if name_err != nil {
    return name_err
  }
  value, value_err := stack_pop(&interp.stack)
  if value_err != nil {
    return value_err
  }

  name_str, ok := variable_name_from_value(name)
  if !ok {
    return Type_Mismatch{note = "!@ requires a variable name"}
  }

  module := interp.module_stack[len(interp.module_stack) - 1]
  module.variables[name_str] = value
  stack_push(&interp.stack, value)
  return nil
}
