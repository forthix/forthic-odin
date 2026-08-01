package raylib_forthic

import "vendor:raylib"
import "../../forthic"

raylib_module_create :: proc() -> ^forthic.Module {
  raylib_module := forthic.module_create("raylib")

  forthic.module_add_native_word(raylib_module, "CLOSE-WINDOW", native_close_window, "( -- )", "Closes window and unloads OpenGL context", {})

  return raylib_module
}

native_close_window :: proc(_: ^forthic.Interpreter) -> forthic.Error {
  raylib.CloseWindow()
  return nil
}
