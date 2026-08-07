package forthic

import "core:sync"

Native_Word_Proc :: proc(interp: ^Interpreter) -> Error

// This is what happens when a Forthic word is executed
Word_Action :: union {
  Native_Word_Proc,
  Forthic_Value,
  [dynamic]Compiled_Word,
}


Word_Doc :: struct {
  stack_effect: string,
  description: string,
  examples: []string,
}

Compiled_Word :: struct {
  name: string,
  action: Word_Action,
  doc: Maybe(Word_Doc),
  requires_ui_thread: bool,
}

compiled_word_execute :: proc(interp: ^Interpreter, word: Compiled_Word, thread_kind: Thread_Kind = .Repl) -> Error {
  switch action in word.action {
  case Native_Word_Proc:
    err : Error
    if word.requires_ui_thread && thread_kind != .Ui {
      sync.mutex_lock(&interp.ui_mutex)
      interp.ui_handoff_count += 1
      interp.ui_pending_word = word
      for interp.ui_pending_word != nil {
        sync.cond_wait(&interp.ui_job_done, &interp.ui_mutex)
      }
      err = interp.ui_error
      sync.mutex_unlock(&interp.ui_mutex)
      return err
    }
    else {
      err = action(interp)
    }

    if word.name != "~>" {
      interp.pending_word_options = nil
    }
    return err
  case Forthic_Value:
    stack_push(&interp.stack, action)
    interp.pending_word_options = nil
    return nil
  case [dynamic]Compiled_Word:
    for w in action {
      w_err := compiled_word_execute(interp, w, thread_kind)
      if w_err != nil {
        return w_err
      }
    }
    interp.pending_word_options = nil
  }
  return nil
}

