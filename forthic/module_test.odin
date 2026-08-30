package forthic

import "core:testing"
import "core:mem/virtual"
import "core:thread"

@(test)
test_module_find_or_create_submodule :: proc(t: ^testing.T) {
  arena: virtual.Arena
  _ = virtual.arena_init_growing(&arena)
  defer virtual.arena_destroy(&arena)
  context.allocator = virtual.arena_allocator(&arena)

  module := module_create("app")

  raylib1 := module_find_or_create_submodule(module, "raylib")
  raylib2 := module_find_or_create_submodule(module, "raylib")
  testing.expect(t, raylib1 == raylib2)

  box2d := module_find_or_create_submodule(module, "box2d")
  testing.expect(t, raylib1 != box2d)
  testing.expect_value(t, box2d.name, "box2d")
}

@(test)
test_module_import_words_prefixed :: proc(t: ^testing.T) {
  arena: virtual.Arena
  _ = virtual.arena_init_growing(&arena)
  defer virtual.arena_destroy(&arena)
  context.allocator = virtual.arena_allocator(&arena)

  src := module_create("raylib")
  module_add_word(src, Compiled_Word{name = "INIT-WINDOW", action = Forthic_Value(i64(42))})

  dest := module_create("app")
  module_import_words_prefixed(dest, src, "raylib")

  _, found_prefixed := module_find_word(dest, "raylib.INIT-WINDOW")
  testing.expect(t, found_prefixed)

  _, found_bare := module_find_word(dest, "INIT-WINDOW")
  testing.expect(t, !found_bare)

  _, src_still_bare := module_find_word(src, "INIT-WINDOW")
  testing.expect(t, src_still_bare)
}

@(test)
test_module_mirror :: proc(t: ^testing.T) {
  arena: virtual.Arena
  _ = virtual.arena_init_growing(&arena)
  defer virtual.arena_destroy(&arena)
  context.allocator = virtual.arena_allocator(&arena)

  target_interp: Interpreter
  interpreter_init(&target_interp)
  defer interpreter_destroy(&target_interp)

  // Registered the same way main.odin registers a real module -- prefixed
  // into target's app module, not pushed onto module_stack bare. This is
  // what module_mirror's own words must actually be found under when a
  // job later drains against target's module_stack.
  source := module_create("demo")
  module_add_builtin_word(source, "PUSH-42", mirror_test_push_42, "( -- n )", "Pushes 42", {})
  interpreter_register_and_import_module(&target_interp, source, "demo")

  queue: Mirror_Job_Queue
  mirror := module_mirror(source, &target_interp, "demo", &queue)
  testing.expect_value(t, mirror.name, "demo")

  word, found := module_find_word(mirror, "PUSH-42")
  testing.expect(t, found)
  doc, has_doc := word.doc.?
  testing.expect(t, has_doc)
  testing.expect_value(t, doc.description, "Pushes 42")

  repl_interp: Interpreter
  interpreter_init(&repl_interp)
  defer interpreter_destroy(&repl_interp)

  job := Mirror_Test_Job{interp = &repl_interp, word = word}

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
