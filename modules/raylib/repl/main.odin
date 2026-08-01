package raylib_repl

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"

import "../../../forthic"
import raylib_forthic "../"

main :: proc() {
  reader: bufio.Reader
  buf: [1024]byte
  bufio.reader_init_with_buf(&reader, os.to_stream(os.stdin), buf[:])
  defer bufio.reader_destroy(&reader)

  interp: forthic.Interpreter
  forthic.interpreter_init(&interp)
  defer forthic.interpreter_destroy(&interp)

  raylib_module := raylib_forthic.raylib_module_create()
  forthic.interpreter_register_and_import_module(&interp, raylib_module, "raylib")

  // Run file if provided
  if len(os.args) > 1 {
    err := forthic.interpreter_run_file(&interp, os.args[1])
    if err != nil {
      fmt.println(err)
    }
  }

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

    positioned_forthic := forthic.Positioned_Forthic{line, nil}
    fmt.println(forthic.interpreter_run(&interp, positioned_forthic))
  }
}
