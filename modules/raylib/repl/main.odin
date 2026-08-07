package raylib_repl

import "core:bufio"
import "core:strings"
import "core:thread"

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

  init_err := forthic.interpreter_run(&interp, forthic.Positioned_Forthic{"ON-INITIALIZE-APP ON-REGISTER-HANDLERS", nil}, .Ui)
  if init_err != nil {
    fmt.println(init_err)
    os.exit(1)
  }

  th := thread.create(repl_thread_proc)
  th.data = &interp
  thread.start(th)

  for !raylib.WindowShouldClose() {
    forthic.interpreter_drain_ui_job(&interp)
    frame_err := forthic.interpreter_run(&interp, forthic.Positioned_Forthic{"ON-DRAW-FRAME", nil}, .Ui)
    if frame_err != nil {
      fmt.println(frame_err)
      os.exit(1)
    }
  }
  raylib.CloseWindow()
}


repl_thread_proc :: proc(t: ^thread.Thread) {
  interp := cast(^forthic.Interpreter)t.data

  reader: bufio.Reader
  buf: [1024]byte
  bufio.reader_init_with_buf(&reader, os.to_stream(os.stdin), buf[:])
  defer bufio.reader_destroy(&reader)

  for {
    line, err := bufio.reader_read_string(&reader, '\n')
    defer delete(line)
    if err != nil {
      break
    }
    line = strings.trim_right(line, "\r\n")
    if line == "" {
      continue
    }
    run_err := forthic.interpreter_run(interp, forthic.Positioned_Forthic{line, nil})
    if run_err != nil {
      fmt.println(run_err)
    }
  }
}


