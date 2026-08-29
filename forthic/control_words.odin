package forthic

builtin_run :: proc(interp: ^Interpreter) -> Error {
  forthic, err := stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  source, is_string := forthic.(string)
  if !is_string {
    return Type_Mismatch{note = "RUN requires a Forthic string"}
  }
  if source == "" {
    return nil
  }
  return interpreter_run(interp, Positioned_Forthic{source, nil})
}

builtin_times_run :: proc(interp: ^Interpreter) -> Error {
  forthic, forthic_err := stack_pop(&interp.stack)
  if forthic_err != nil {
    return forthic_err
  }
  num_times, num_err := stack_pop(&interp.stack)
  if num_err != nil {
    return num_err
  }

  n, is_int := num_times.(i64)
  if !is_int {
    return Type_Mismatch{note = "TIMES-RUN requires an int count"}
  }
  source, is_string := forthic.(string)
  if !is_string {
    return Type_Mismatch{note = "TIMES-RUN requires a Forthic string"}
  }
  if source == "" {
    return nil
  }

  for _ in 0..<n {
    err := interpreter_run(interp, Positioned_Forthic{source, nil})
    if err != nil {
      return err
    }
  }
  return nil
}

builtin_if :: proc(interp: ^Interpreter) -> Error {
  else_value, else_err := stack_pop(&interp.stack)
  if else_err != nil {
    return else_err
  }
  then_value, then_err := stack_pop(&interp.stack)
  if then_err != nil {
    return then_err
  }
  bool_value, bool_err := stack_pop(&interp.stack)
  if bool_err != nil {
    return bool_err
  }

  is_true, is_bool := bool_value.(bool)
  if !is_bool {
    return Type_Mismatch{note = "IF requires a boolean"}
  }

  if is_true {
    stack_push(&interp.stack, then_value)
  } else {
    stack_push(&interp.stack, else_value)
  }
  return nil
}

builtin_if_run :: proc(interp: ^Interpreter) -> Error {
  else_forthic, else_err := stack_pop(&interp.stack)
  if else_err != nil {
    return else_err
  }
  then_forthic, then_err := stack_pop(&interp.stack)
  if then_err != nil {
    return then_err
  }
  bool_value, bool_err := stack_pop(&interp.stack)
  if bool_err != nil {
    return bool_err
  }

  is_true, is_bool := bool_value.(bool)
  if !is_bool {
    return Type_Mismatch{note = "IF-RUN requires a boolean"}
  }

  branch := else_forthic
  if is_true {
    branch = then_forthic
  }

  source, is_string := branch.(string)
  if !is_string {
    return Type_Mismatch{note = "IF-RUN requires Forthic strings for its branches"}
  }
  if source == "" {
    return nil
  }
  return interpreter_run(interp, Positioned_Forthic{source, nil})
}

builtin_when :: proc(interp: ^Interpreter) -> Error {
  forthic, forthic_err := stack_pop(&interp.stack)
  if forthic_err != nil {
    return forthic_err
  }
  bool_value, bool_err := stack_pop(&interp.stack)
  if bool_err != nil {
    return bool_err
  }

  is_true, is_bool := bool_value.(bool)
  if !is_bool {
    return Type_Mismatch{note = "WHEN requires a boolean"}
  }
  if !is_true {
    return nil
  }

  source, is_string := forthic.(string)
  if !is_string {
    return Type_Mismatch{note = "WHEN requires a Forthic string"}
  }
  if source == "" {
    return nil
  }
  return interpreter_run(interp, Positioned_Forthic{source, nil})
}
