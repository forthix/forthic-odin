package raylib_repl

import "core:bufio"
import "core:strings"
import "core:thread"

import "core:fmt"
import "core:os"
import "vendor:raylib"

import "../../../forthic"
import raylib_forthic "../"
import dungeon_forthic "../../dungeon"

main :: proc() {
  ui_interp: forthic.Interpreter
  forthic.interpreter_init(&ui_interp)
  defer forthic.interpreter_destroy(&ui_interp)

  raylib_module := raylib_forthic.raylib_module_create()
  forthic.interpreter_register_and_import_module(&ui_interp, raylib_module, "raylib")

  dungeon_module := dungeon_forthic.dungeon_module_create()
  forthic.interpreter_register_and_import_module(&ui_interp, dungeon_module, "dungeon")

  queue: forthic.Mirror_Job_Queue

  repl_interp: forthic.Interpreter
  forthic.interpreter_init(&repl_interp)
  defer forthic.interpreter_destroy(&repl_interp)

  raylib_mirror_module := forthic.module_mirror(raylib_module, &ui_interp, &queue)
  forthic.interpreter_register_and_import_module(&repl_interp, raylib_mirror_module, "raylib")

  dungeon_mirror_module := forthic.module_mirror(dungeon_module, &ui_interp, &queue)
  forthic.interpreter_register_and_import_module(&repl_interp, dungeon_mirror_module, "dungeon")

  if len(os.args) > 1 {
    err := forthic.interpreter_run_file(&ui_interp, os.args[1])
    if err != nil {
      fmt.println(err)
      os.exit(1)
    }
  }

  init_err := forthic.interpreter_run(&ui_interp, forthic.Positioned_Forthic{"ON-INITIALIZE-APP ON-REGISTER-HANDLERS", nil})
  if init_err != nil {
    fmt.println(init_err)
    os.exit(1)
  }

  th := thread.create(repl_thread_proc)
  th.data = &repl_interp
  thread.start(th)

  for !raylib.WindowShouldClose() {
    forthic.mirror_job_queue_drain(&queue, &ui_interp)
    frame_err := forthic.interpreter_run(&ui_interp, forthic.Positioned_Forthic{"ON-DRAW-FRAME", nil})
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
    fmt.print("forthic> ")

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
    fmt.println(interp.stack.items[:])
  }
}
