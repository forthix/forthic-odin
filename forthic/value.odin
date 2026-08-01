package forthic

Dot_Symbol :: distinct string
Record :: map[Dot_Symbol]Forthic_Value

Forthic_Value :: union {
  bool,
  i64,
  f64,
  string,
  Dot_Symbol,
  Record,
  [dynamic]Forthic_Value,
}

forthic_value_equal :: proc(a, b: Forthic_Value) -> bool {
  switch va in a {
  case bool:
    vb, ok := b.(bool)
    return ok  && va == vb
  case i64:
    vb, ok := b.(i64)
    return ok  && va == vb
  case f64:
    vb, ok := b.(f64)
    return ok  && va == vb
  case string:
    vb, ok := b.(string)
    return ok  && va == vb
  case Dot_Symbol:
    vb, ok := b.(Dot_Symbol)
    return ok  && va == vb
  case [dynamic]Forthic_Value:
    vb, ok := b.([dynamic]Forthic_Value)
    if !ok || len(va) != len(vb) {
      return false
    }
    for i :=0; i < len(va); i += 1 {
      if !forthic_value_equal(va[i], vb[i]) {
        return false
      }
    }
    return true
  case Record:
    vb, ok := b.(Record)
    if !ok || len(va) != len(vb) {
      return false
    }
    for key, value in va {
      vb_value, found := vb[key]
      if !found || !forthic_value_equal(value, vb_value) {
        return false
      }
    }
    return true
  case:
    return b == nil
  }
  return false
}

record_get_bool :: proc(record: Record, name: string, default: bool) -> bool {
  return record_get(record, name, default)
}

record_get_int :: proc(record: Record, name: string, default: i64) -> i64 {
  return record_get(record, name, default)
}

record_get_float :: proc(record: Record, name: string, default: f64) -> f64 {
  return record_get(record, name, default)
}

record_get_string :: proc(record: Record, name: string, default: string) -> string {
  return record_get(record, name, default)
}

record_get :: proc(record: Record, name: string, default: $T) -> T {
  value, is_present := record[Dot_Symbol(name)]
  if !is_present {
    return default
  }

  typed_value, is_T := value.(T)
  if !is_T {
    return default
  }
  return typed_value
}
