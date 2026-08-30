// These are words for manipulating Forthic modules

package forthic

// ( module_name:string -- )
builtin_module :: proc(interp: ^Interpreter) -> Error {
  mod_name, err := pop_string(interp, "MODULE")
  if err != nil {
    return err
  }

  top_module := interp.module_stack[len(interp.module_stack) - 1]
  submodule := module_find_or_create_submodule(top_module, mod_name)
  append(&interp.module_stack, submodule)
  return nil
}

// ( -- )
builtin_end_module :: proc(interp: ^Interpreter) -> Error {
  if len(interp.module_stack) <= 1 {
    return Extra_End_Module{ location = Code_Location{} }
  }
  pop(&interp.module_stack)
  return nil
}

// ( -- )
builtin_app_module :: proc(interp: ^Interpreter) -> Error {
  app_module := interp.module_stack[0]
  append(&interp.module_stack, app_module)
  return nil
}
