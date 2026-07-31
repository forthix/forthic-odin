package forthic

import "core:testing"
import "core:mem/virtual"

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
test_module_requires_ui_thread_defaults_false :: proc(t: ^testing.T) {
  arena: virtual.Arena
  _ = virtual.arena_init_growing(&arena)
  defer virtual.arena_destroy(&arena)
  context.allocator = virtual.arena_allocator(&arena)

  module := module_create("app")
  testing.expect_value(t, module.requires_ui_thread, false)
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
