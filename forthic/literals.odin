package forthic

import "core:strconv"
import "core:strings"

Literal_Handler :: proc(text: string) -> (Forthic_Value, bool)

literal_to_bool :: proc(text: string) -> (Forthic_Value, bool) {
  switch text {
  case "TRUE":
    return Forthic_Value(bool(true)), true
  case "FALSE":
    return Forthic_Value(bool(false)), true
  case:
    return Forthic_Value{}, false
  }
}

literal_to_float :: proc(text: string) -> (Forthic_Value, bool) {
  if !strings.contains(text, ".") {
    return Forthic_Value{}, false
  }

  float_val, ok := strconv.parse_f64(text)
  if !ok {
    return Forthic_Value{}, false
  }
  return Forthic_Value(float_val), true
}

literal_to_int :: proc(text: string) -> (Forthic_Value, bool) {
  if strings.contains(text, ".") {
    return Forthic_Value{}, false
  }

  int_val, ok := strconv.parse_i64(text)
  if !ok {
    return Forthic_Value{}, false
  }
  return Forthic_Value(int_val), true
}
