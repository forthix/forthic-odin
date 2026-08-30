package forthic

import "core:strings"

// Typed stack-pop helpers: cut the repeated "pop, type-assert, build a
// Type_Mismatch" prologue that showed up at the top of most builtin_*
// procs. word_name is only used for the error message.

pop_string :: proc(interp: ^Interpreter, word_name: string) -> (string, Error) {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return "", err
  }
  s, ok := value.(string)
  if !ok {
    return "", Type_Mismatch{note = strings.concatenate({word_name, " requires a string"})}
  }
  return s, nil
}

pop_array :: proc(interp: ^Interpreter, word_name: string) -> ([dynamic]Forthic_Value, Error) {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return nil, err
  }
  arr, ok := value.([dynamic]Forthic_Value)
  if !ok {
    return nil, Type_Mismatch{note = strings.concatenate({word_name, " requires an array"})}
  }
  return arr, nil
}
