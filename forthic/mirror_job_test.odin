package forthic

import "core:testing"
import "core:thread"

mirror_test_push_42 :: proc(interp: ^Interpreter) -> Error {
  stack_push(&interp.stack, Forthic_Value(i64(42)))
  return nil
}

Mirror_Test_Job :: struct {
  interp: ^Interpreter,
  word: Compiled_Word,
  result: Error,
}

mirror_test_job_thread_proc :: proc(t: ^thread.Thread) {
  job := cast(^Mirror_Test_Job)t.data
  job.result = compiled_word_execute(job.interp, job.word)
}

@(test)
test_compiled_word_execute_forwards_mirror_action :: proc(t: ^testing.T) {
  target_interp: Interpreter
  interpreter_init(&target_interp)
  defer interpreter_destroy(&target_interp)
  module_add_word(target_interp.module_stack[0], Compiled_Word{name = "PUSH-42", action = Builtin_Word_Proc(mirror_test_push_42)})

  queue: Mirror_Job_Queue

  repl_interp: Interpreter
  interpreter_init(&repl_interp)
  defer interpreter_destroy(&repl_interp)

  mirror_word := Compiled_Word{
    name = "MIRROR-WORD",
    action = Mirror_Action{word_name = "PUSH-42", target = &target_interp, queue = &queue},
  }
  job := Mirror_Test_Job{interp = &repl_interp, word = mirror_word}

  th := thread.create(mirror_test_job_thread_proc)
  th.data = &job
  thread.start(th)

  for !thread.is_done(th) {
    mirror_job_queue_drain(&queue, &target_interp)
  }
  thread.join(th)
  thread.destroy(th)

  testing.expect(t, job.result == nil)

  top, pop_err := stack_pop(&repl_interp.stack)
  testing.expect(t, pop_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(42))))
}

@(test)
test_compiled_word_execute_mirror_action_preserves_calling_stack :: proc(t: ^testing.T) {
  target_interp: Interpreter
  interpreter_init(&target_interp)
  defer interpreter_destroy(&target_interp)
  module_add_word(target_interp.module_stack[0], Compiled_Word{name = "PUSH-42", action = Builtin_Word_Proc(mirror_test_push_42)})

  queue: Mirror_Job_Queue

  repl_interp: Interpreter
  interpreter_init(&repl_interp)
  defer interpreter_destroy(&repl_interp)
  stack_push(&repl_interp.stack, Forthic_Value(i64(7)))

  mirror_word := Compiled_Word{
    name = "MIRROR-WORD",
    action = Mirror_Action{word_name = "PUSH-42", target = &target_interp, queue = &queue},
  }
  job := Mirror_Test_Job{interp = &repl_interp, word = mirror_word}

  th := thread.create(mirror_test_job_thread_proc)
  th.data = &job
  thread.start(th)

  for !thread.is_done(th) {
    mirror_job_queue_drain(&queue, &target_interp)
  }
  thread.join(th)
  thread.destroy(th)

  testing.expect(t, job.result == nil)
  testing.expect_value(t, stack_len(&repl_interp.stack), 2)

  top, top_err := stack_pop(&repl_interp.stack)
  testing.expect(t, top_err == nil)
  testing.expect(t, forthic_value_equal(top, Forthic_Value(i64(42))))

  bottom, bottom_err := stack_pop(&repl_interp.stack)
  testing.expect(t, bottom_err == nil)
  testing.expect(t, forthic_value_equal(bottom, Forthic_Value(i64(7))))
}

@(test)
test_compiled_word_execute_mirror_action_unknown_word :: proc(t: ^testing.T) {
  target_interp: Interpreter
  interpreter_init(&target_interp)
  defer interpreter_destroy(&target_interp)

  queue: Mirror_Job_Queue

  repl_interp: Interpreter
  interpreter_init(&repl_interp)
  defer interpreter_destroy(&repl_interp)

  mirror_word := Compiled_Word{
    name = "MIRROR-WORD",
    action = Mirror_Action{word_name = "NOT-A-REAL-WORD", target = &target_interp, queue = &queue},
  }
  job := Mirror_Test_Job{interp = &repl_interp, word = mirror_word}

  th := thread.create(mirror_test_job_thread_proc)
  th.data = &job
  thread.start(th)

  for !thread.is_done(th) {
    mirror_job_queue_drain(&queue, &target_interp)
  }
  thread.join(th)
  thread.destroy(th)

  _, is_unknown := job.result.(Unknown_Word)
  testing.expect(t, is_unknown)
}
