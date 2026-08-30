package forthic

import "core:fmt"

// ( a -- )
builtin_print :: proc(interp: ^Interpreter) -> Error {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return err
  }
  fmt.println(value)
  return nil
}
