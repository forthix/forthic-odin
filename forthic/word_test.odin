package forthic

import "core:testing"
import "core:thread"

builtin_push_42 :: proc(interp: ^Interpreter) -> Error {
  stack_push(&interp.stack, Forthic_Value(i64(42)))
  return nil
}

Ui_Test_Job :: struct {
  interp: ^Interpreter,
  word: Compiled_Word,
  result: Error,
}

ui_test_job_thread_proc :: proc(t: ^thread.Thread) {
  job := cast(^Ui_Test_Job)t.data
  job.result = compiled_word_execute(job.interp, job.word)
}

@(test)
test_compiled_word_execute_hands_off_ui_thread_word :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  word := Compiled_Word{name = "UI-WORD", action = Builtin_Word_Proc(builtin_push_42), requires_ui_thread = true}
  job := Ui_Test_Job{interp = &interp, word = word}

  th := thread.create(ui_test_job_thread_proc)
  th.data = &job
  thread.start(th)

  for !thread.is_done(th) {
    interpreter_drain_ui_job(&interp)
  }
  thread.join(th)
  thread.destroy(th)

  testing.expect(t, job.result == nil)
  testing.expect_value(t, interp.ui_handoff_count, i32(1))

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(42))))
}

@(test)
test_compiled_word_execute_no_handoff_when_already_on_ui_thread :: proc(t: ^testing.T) {
  interp: Interpreter
  interpreter_init(&interp)
  defer interpreter_destroy(&interp)

  word := Compiled_Word{name = "UI-WORD", action = Builtin_Word_Proc(builtin_push_42), requires_ui_thread = true}

  err := compiled_word_execute(&interp, word, .Ui)
  testing.expect(t, err == nil)
  testing.expect_value(t, interp.ui_handoff_count, i32(0))

  top, pop_err := stack_pop(&interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(42))))
}
