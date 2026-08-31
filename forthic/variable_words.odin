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

// Module variable wins if already declared (so VARIABLES-declared names
// stay genuinely shared); else the current local frame, auto-created there
// (so a word's scratch variables are private to that call); else (no active
// frame -- top-level execution) the module, matching pre-local-scoping
// behavior.
set_variable_value :: proc(interp: ^Interpreter, name: string, value: Forthic_Value) {
  module := interp.module_stack[len(interp.module_stack) - 1]
  if _, declared := module.variables[name]; declared {
    module.variables[name] = value
    return
  }
  if len(interp.local_frames) > 0 {
    interp.local_frames[len(interp.local_frames) - 1][name] = value
    return
  }
  module.variables[name] = value
}

// Same precedence as set_variable_value; ok is false if declared nowhere.
get_variable_value :: proc(interp: ^Interpreter, name: string) -> (Forthic_Value, bool) {
  if len(interp.local_frames) > 0 {
    if value, declared := interp.local_frames[len(interp.local_frames) - 1][name]; declared {
      return value, true
    }
  }
  module := interp.module_stack[len(interp.module_stack) - 1]
  return module.variables[name]
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

  set_variable_value(interp, name_str, value)
  return nil
}

// ( name -- value )
builtin_get_variable :: proc(interp: ^Interpreter) -> Error {
  name_str, err := pop_name(interp, "@")
  if err != nil {
    return err
  }

  value, declared := get_variable_value(interp, name_str)
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

  set_variable_value(interp, name_str, value)
  stack_push(&interp.stack, value)
  return nil
}
