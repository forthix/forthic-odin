package forthic

Forthic_Value :: union {
  bool,
  i64,
  f64,
  string,
  [dynamic]Forthic_Value,
  map[string]Forthic_Value
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
  case map[string]Forthic_Value:
    vb, ok := b.(map[string]Forthic_Value)
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
