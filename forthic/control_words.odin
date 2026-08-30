package forthic

// ( forthic:string -- ? )
builtin_run :: proc(interp: ^Interpreter) -> Error {
  source, err := pop_string(interp, "RUN")
  if err != nil {
    return err
  }
  if source == "" {
    return nil
  }
  return interpreter_run(interp, Positioned_Forthic{source, nil})
}

// ( filename:string -- object )
// Runs filename like RUN runs a string, but on an isolated scratch stack --
// a bug in the loaded file can't corrupt the caller's stack, and is
// reported as a clear error instead of silent corruption. The file must
// leave exactly one value.
builtin_load_object :: proc(interp: ^Interpreter) -> Error {
  filename, err := pop_string(interp, "LOAD-OBJECT")
  if err != nil {
    return err
  }

  caller_stack := interp.stack
  interp.stack = Stack{items = make([dynamic]Forthic_Value, 0, interp.default_allocator)}

  run_err := interpreter_run_file(interp, filename)
  loaded_stack := interp.stack
  interp.stack = caller_stack
  defer stack_destroy(&loaded_stack)

  if run_err != nil {
    return run_err
  }
  if stack_len(&loaded_stack) != 1 {
    return Type_Mismatch{note = "LOAD-OBJECT requires the file to leave exactly one value on the stack"}
  }

  object, _ := stack_pop(&loaded_stack)
  stack_push(&interp.stack, object)
  return nil
}

// ( num_times:int forthic:string -- ? )
builtin_times_run :: proc(interp: ^Interpreter) -> Error {
  source, source_err := pop_string(interp, "TIMES-RUN")
  if source_err != nil {
    return source_err
  }
  n, n_err := pop_int(interp, "TIMES-RUN")
  if n_err != nil {
    return n_err
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

// ( bool then_value else_value -- chosen )
builtin_if :: proc(interp: ^Interpreter) -> Error {
  else_value, else_err := stack_pop(&interp.stack)
  if else_err != nil {
    return else_err
  }
  then_value, then_err := stack_pop(&interp.stack)
  if then_err != nil {
    return then_err
  }
  is_true, bool_err := pop_bool(interp, "IF")
  if bool_err != nil {
    return bool_err
  }

  if is_true {
    stack_push(&interp.stack, then_value)
  } else {
    stack_push(&interp.stack, else_value)
  }
  return nil
}

// ( bool then_forthic else_forthic -- ? )
// Only the chosen branch is required to be a string -- the other one is
// never inspected, matching IF's "pure value selection" laziness.
builtin_if_run :: proc(interp: ^Interpreter) -> Error {
  else_forthic, else_err := stack_pop(&interp.stack)
  if else_err != nil {
    return else_err
  }
  then_forthic, then_err := stack_pop(&interp.stack)
  if then_err != nil {
    return then_err
  }
  is_true, bool_err := pop_bool(interp, "IF-RUN")
  if bool_err != nil {
    return bool_err
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

// ( bool forthic -- ? )
// forthic's type is only checked when bool is true -- WHEN is a no-op
// (forthic never inspected) when bool is false.
builtin_when :: proc(interp: ^Interpreter) -> Error {
  forthic, forthic_err := stack_pop(&interp.stack)
  if forthic_err != nil {
    return forthic_err
  }
  is_true, bool_err := pop_bool(interp, "WHEN")
  if bool_err != nil {
    return bool_err
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
