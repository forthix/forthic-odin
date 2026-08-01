package raylib_repl

import "core:fmt"
import "core:os"
import "vendor:raylib"

import "../../../forthic"
import raylib_forthic "../"

main :: proc() {
  interp: forthic.Interpreter
  forthic.interpreter_init(&interp)
  defer forthic.interpreter_destroy(&interp)

  raylib_module := raylib_forthic.raylib_module_create()
  forthic.interpreter_register_and_import_module(&interp, raylib_module, "raylib")

  if len(os.args) > 1 {
    err := forthic.interpreter_run_file(&interp, os.args[1])
    if err != nil {
      fmt.println(err)
      os.exit(1)
    }
  }

  init_err := forthic.interpreter_run(&interp, forthic.Positioned_Forthic{"ON-INITIALIZE-APP ON-REGISTER-HANDLERS", nil})
  if init_err != nil {
    fmt.println(init_err)
    os.exit(1)
  }

  for !raylib.WindowShouldClose() {
    frame_err := forthic.interpreter_run(&interp, forthic.Positioned_Forthic{"ON-DRAW-FRAME", nil})
    if frame_err != nil {
      fmt.println(frame_err)
      os.exit(1)
    }
  }
  raylib.CloseWindow()
}
