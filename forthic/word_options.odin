package forthic

Word_Options :: struct {
  values: map[string]Forthic_Value,
}

word_options_from_record :: proc(record: map[string]Forthic_Value) -> Word_Options {
  return Word_Options{ values = record}
}

word_options_get_bool :: proc(options: Word_Options, name: string, default: bool) -> bool {
  return word_options_get(options, name, default)
}

word_options_get_int :: proc(options: Word_Options, name: string, default: i64) -> i64 {
  return word_options_get(options, name, default)
}

word_options_get_float :: proc(options: Word_Options, name: string, default: f64) -> f64 {
  return word_options_get(options, name, default)
}

word_options_get_string :: proc(options: Word_Options, name: string, default: string) -> string {
  return word_options_get(options, name, default)
}

word_options_get :: proc(options: Word_Options, name: string, default: $T) -> T {
  value, is_present := options.values[name]
  if !is_present {
    return default
  }

  typed_value, is_T := value.(T)
  if !is_T {
    return default
  }
  return typed_value
}
