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
import log_forthic "../../log"
import sqlite_forthic "../../sqlite"

// Loads a Forthic-file-backed module on ui_interp, exiting the process on
// any load error (missing file, parse error, etc.) -- there's no
// reasonable way to keep running without it.
load_forthic_module :: proc(ui_interp: ^forthic.Interpreter, name: string, path: string) -> ^forthic.Module {
  module, err := forthic.module_create_from_forthic_file(ui_interp, name, path)
  if err != nil {
    fmt.println(err)
    os.exit(1)
  }
  return module
}

// Registers an already-created module on ui_interp under prefix, and wires
// up the matching mirror module on repl_interp so REPL-typed Forthic can
// call the same words (forwarded across the queue to run on ui_interp).
register_module :: proc(
  ui_interp: ^forthic.Interpreter,
  repl_interp: ^forthic.Interpreter,
  queue: ^forthic.Mirror_Job_Queue,
  module: ^forthic.Module,
  prefix: string,
) {
  forthic.interpreter_register_and_import_module(ui_interp, module, prefix)
  mirror_module := forthic.module_mirror(module, ui_interp, prefix, queue)
  forthic.interpreter_register_and_import_module(repl_interp, mirror_module, prefix)
}

// Runs the app's own Forthic file (its word definitions and hooks), if one
// was given on the command line.
run_app_script :: proc(ui_interp: ^forthic.Interpreter) {
  if len(os.args) <= 1 {
    return
  }
  err := forthic.interpreter_run_file(ui_interp, os.args[1])
  if err != nil {
    fmt.println(err)
    os.exit(1)
  }
}

// Calls the app-defined ON-INITIALIZE-APP hook once, before the window's
// first frame.
initialize_app :: proc(ui_interp: ^forthic.Interpreter) {
  err := forthic.interpreter_run(ui_interp, forthic.Positioned_Forthic{"ON-INITIALIZE-APP", nil})
  if err != nil {
    fmt.println(err)
    os.exit(1)
  }
}

// Drives the app's own ON-DRAW-FRAME hook once per frame until the window
// closes, draining any REPL-thread calls queued for this interpreter
// first so they run on the same thread as raylib's own calls.
run_frame_loop :: proc(ui_interp: ^forthic.Interpreter, queue: ^forthic.Mirror_Job_Queue) {
  for !raylib.WindowShouldClose() {
    forthic.mirror_job_queue_drain(queue, ui_interp)
    frame_err := forthic.interpreter_run(ui_interp, forthic.Positioned_Forthic{"ON-DRAW-FRAME", nil})
    if frame_err != nil {
      fmt.println(frame_err)
      os.exit(1)
    }
  }
  raylib.CloseWindow()
}

main :: proc() {
  ui_interp: forthic.Interpreter
  forthic.interpreter_init(&ui_interp)
  defer forthic.interpreter_destroy(&ui_interp)

  repl_interp: forthic.Interpreter
  forthic.interpreter_init(&repl_interp)
  defer forthic.interpreter_destroy(&repl_interp)

  queue: forthic.Mirror_Job_Queue

  // Registration order matters for the Forthic-file-backed modules: each
  // one's word references are resolved against ui_interp as it's compiled
  // (see module_create_from_forthic_file), so a module must be registered
  // after every other module it calls into.
  register_module(&ui_interp, &repl_interp, &queue, raylib_forthic.raylib_module_create(), "raylib")
  register_module(&ui_interp, &repl_interp, &queue, dungeon_forthic.dungeon_module_create(), "dungeon")
  register_module(&ui_interp, &repl_interp, &queue, log_forthic.log_module_create(), "log")
  register_module(&ui_interp, &repl_interp, &queue, load_forthic_module(&ui_interp, "message-log", "modules/raylib/lib/message-log.forthic"), "message-log")
  register_module(&ui_interp, &repl_interp, &queue, load_forthic_module(&ui_interp, "status-bar", "modules/raylib/lib/status-bar.forthic"), "status-bar")
  register_module(&ui_interp, &repl_interp, &queue, sqlite_forthic.sqlite_module_create(), "sqlite")
  register_module(&ui_interp, &repl_interp, &queue, load_forthic_module(&ui_interp, "history", "lib/history.forthic"), "history")
  register_module(&ui_interp, &repl_interp, &queue, load_forthic_module(&ui_interp, "movement", "modules/raylib/lib/movement.forthic"), "movement")
  register_module(&ui_interp, &repl_interp, &queue, load_forthic_module(&ui_interp, "corridor-view", "modules/raylib/lib/corridor-view.forthic"), "corridor-view")

  run_app_script(&ui_interp)
  initialize_app(&ui_interp)

  th := thread.create(repl_thread_proc)
  th.data = &repl_interp
  thread.start(th)

  run_frame_loop(&ui_interp, &queue)
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
