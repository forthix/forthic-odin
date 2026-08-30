package forthic

import "core:fmt"
import "core:strings"

builtin_to_str :: proc(interp: ^Interpreter) -> Error {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return err
  }
  stack_push(&interp.stack, Forthic_Value(forthic_value_to_string(value)))
  return nil
}

forthic_value_to_string :: proc(value: Forthic_Value) -> string {
  if value == nil {
    return ""
  }
  switch v in value {
  case bool:
    return v ? "true" : "false"
  case i64:
    return fmt.tprintf("%d", v)
  case f64:
    return fmt.tprintf("%v", v)
  case string:
    return v
  case Dot_Symbol:
    return string(v)
  case Record:
    return fmt.tprintf("%v", v)
  case [dynamic]Forthic_Value:
    return fmt.tprintf("%v", v)
  }
  return ""
}

builtin_concat :: proc(interp: ^Interpreter) -> Error {
  value, err := stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  arr, is_array := value.([dynamic]Forthic_Value)
  if !is_array {
    return Type_Mismatch{note = "CONCAT requires an array of strings"}
  }

  builder: strings.Builder
  strings.builder_init(&builder)
  for item in arr {
    s, is_string := item.(string)
    if !is_string {
      return Type_Mismatch{note = "CONCAT requires an array of strings"}
    }
    strings.write_string(&builder, s)
  }

  stack_push(&interp.stack, Forthic_Value(strings.to_string(builder)))
  return nil
}
