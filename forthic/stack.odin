package forthic

Stack :: struct {
  items: [dynamic]Forthic_Value
}

stack_push :: proc(stack: ^Stack, item: Forthic_Value) {
  append(&stack.items, item)
}

stack_pop :: proc(stack: ^Stack) -> (Forthic_Value, Error) {
  if len(stack.items) == 0 {
    return nil, Stack_Underflow{}
  }
  return pop(&stack.items), nil
}

stack_peek :: proc(stack: ^Stack) -> (Forthic_Value, bool) {
  if len(stack.items) == 0 {
    return nil, false
  }
  return stack.items[len(stack.items) - 1], true
}

stack_destroy :: proc(stack: ^Stack) {
  delete(stack.items)
}

stack_len :: proc(stack: ^Stack) -> int {
  return len(stack.items)
}

stack_clear :: proc(stack: ^Stack) {
  clear(&stack.items)
}

stack_get :: proc(stack: ^Stack, index: int) -> (Forthic_Value, bool) {
  if index >= len(stack.items) {
    return nil, false
  }
  return stack.items[index], true
}

stack_dup :: proc(stack: ^Stack) -> Stack {
  new_items : [dynamic]Forthic_Value
  reserve(&new_items, len(stack.items))
  for item in stack.items {
    append(&new_items, item)
  }
  return Stack{
    items = new_items
  }
}

stack_is_empty :: proc(stack: ^Stack) -> bool {
  return len(stack.items) == 0
}

stack_pop_record :: proc(stack: ^Stack, note: string) -> (Record, Error) {
  value, err := stack_pop(stack)
  if err != nil {
    return nil, err
  }

  record, is_record := value.(Record)
  if !is_record {
    return nil, Type_Mismatch{ note = note }
  }
  return record, nil
}
