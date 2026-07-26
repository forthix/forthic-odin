package main

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"
import "../forthic"

main :: proc() {
  reader: bufio.Reader
  buf: [1024]byte
  bufio.reader_init_with_buf(&reader, os.to_stream(os.stdin), buf[:])
  defer bufio.reader_destroy(&reader)

  interp: forthic.Interpreter
  forthic.interpreter_init(&interp)
  defer forthic.interpreter_destroy(&interp)

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
