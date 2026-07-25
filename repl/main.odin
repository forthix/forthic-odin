package main

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"
import "../interpreter"

main :: proc() {
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

    fmt.println(interpreter.run(line))
  }
}
