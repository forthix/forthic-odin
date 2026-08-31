package forthic

// ( value:number breakpoints:array default -- key )
// Classifies a continuous value into a named bucket. breakpoints is an
// ascending array of { .below N .key K } records; returns the .key of the
// first breakpoint where value <= .below, or default if value exceeds all
// of them. Pairs naturally with JQ@ for the second half of "partition a
// range, then map the partition to a value": BUCKET picks the key, JQ@
// looks it up in a plain record.
builtin_bucket :: proc(interp: ^Interpreter) -> Error {
  default_value, default_err := stack_pop(&interp.stack)
  if default_err != nil {
    return default_err
  }
  breakpoints, bp_err := pop_array(interp, "BUCKET")
  if bp_err != nil {
    return bp_err
  }
  raw_value, value_err := stack_pop(&interp.stack)
  if value_err != nil {
    return value_err
  }

  value, is_num := forthic_value_as_f64(raw_value)
  if !is_num {
    return Type_Mismatch{note = "BUCKET requires a numeric value"}
  }

  for bp in breakpoints {
    rec, is_rec := bp.(Record)
    if !is_rec {
      return Type_Mismatch{note = "BUCKET breakpoints must be records with .below and .key"}
    }

    below_value, has_below := rec[Dot_Symbol("below")]
    if !has_below {
      return Type_Mismatch{note = "BUCKET breakpoints must have a .below field"}
    }
    below, below_is_num := forthic_value_as_f64(below_value)
    if !below_is_num {
      return Type_Mismatch{note = "BUCKET breakpoint .below must be numeric"}
    }

    if value <= below {
      key, has_key := rec[Dot_Symbol("key")]
      if !has_key {
        return Type_Mismatch{note = "BUCKET breakpoints must have a .key field"}
      }
      stack_push(&interp.stack, key)
      return nil
    }
  }

  stack_push(&interp.stack, default_value)
  return nil
}
