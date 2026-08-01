package raylib_forthic

import "core:strings"
import "vendor:raylib"
import "../../forthic"

raylib_module_create :: proc() -> ^forthic.Module {
  raylib_module := forthic.module_create("raylib")

  forthic.module_add_native_word(
    raylib_module, "INIT-WINDOW", native_init_window, "( record -- )",
    "Initializes window and OpenGL context. Fields: width (int, default 800), height (int, default 600), title (string, default \"Forthic\").",
    {`{ .width 800 .height 600 .title "Game" } raylib.INIT-WINDOW`},
  )
  forthic.module_add_native_word(
    raylib_module, "WINDOW-SHOULD-CLOSE?", native_window_should_close, "( -- bool )",
    "Pushes true if the window's close button or ESC has been pressed.",
    {"raylib.WINDOW-SHOULD-CLOSE?"},
  )
  forthic.module_add_native_word(
    raylib_module, "CLOSE-WINDOW", native_close_window, "( -- )",
    "Closes window and unloads OpenGL context.",
    {"raylib.CLOSE-WINDOW"},
  )

  forthic.module_add_native_word(
    raylib_module, "BEGIN-DRAWING", native_begin_drawing, "( -- )",
    "Set up canvas to start drawing.",
    {"raylib.BEGIN-DRAWING"},
  )
  forthic.module_add_native_word(
    raylib_module, "CLEAR-BACKGROUND", native_clear_background, "( record -- )",
    "Clears the background with the given color. Fields: r, g, b, a (int 0-255, each defaults to 255).",
    {`{ .r 245 .g 245 .b 245 .a 255 } raylib.CLEAR-BACKGROUND`},
  )
  forthic.module_add_native_word(
    raylib_module, "DRAW-RECTANGLE", native_draw_rectangle, "( record -- )",
    "Draws a color-filled rectangle. Fields: x, y, width, height (int, default 0), color (record with r, g, b, a, default all 255).",
    {`{ .x 10 .y 10 .width 100 .height 50 .color { .r 255 .g 0 .b 0 .a 255 } } raylib.DRAW-RECTANGLE`},
  )
  forthic.module_add_native_word(
    raylib_module, "DRAW-TEXT", native_draw_text, "( record -- )",
    "Draws text using the default font. Fields: text (string, default \"\"), posX, posY (int, default 0), fontSize (int, default 0), color (record with r, g, b, a, default all 255).",
    {`{ .text "Hello" .posX 10 .posY 10 .fontSize 20 .color { .r 0 .g 0 .b 0 .a 255 } } raylib.DRAW-TEXT`},
  )
  forthic.module_add_native_word(
    raylib_module, "END-DRAWING", native_end_drawing, "( -- )",
    "End canvas drawing and swap buffers.",
    {"raylib.END-DRAWING"},
  )

  return raylib_module
}

native_close_window :: proc(_: ^forthic.Interpreter) -> forthic.Error {
  raylib.CloseWindow()
  return nil
}

native_init_window :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  value, err := forthic.stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  record, is_record := value.(forthic.Record)
  if !is_record {
    return forthic.Type_Mismatch{note = "INIT-WINDOW requires a record with width, height, and title"}
  }

  width := forthic.record_get_int(record, "width", 800)
  height := forthic.record_get_int(record, "height", 600)
  title := forthic.record_get_string(record, "title", "Forthic")

  title_cstr := strings.clone_to_cstring(title)
  defer delete(title_cstr)
  raylib.InitWindow(i32(width), i32(height), title_cstr)
  return nil
}

native_window_should_close :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  should_close := raylib.WindowShouldClose()
  forthic.stack_push(&interp.stack, forthic.Forthic_Value(should_close))
  return nil
}

native_begin_drawing :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  raylib.BeginDrawing()
  return nil
}

native_end_drawing :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  raylib.EndDrawing()
  return nil
}


native_clear_background :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "CLEAR-BACKGROUND requires a record with r, g, b, a" )
  if err != nil {
    return err
  }

  raylib.ClearBackground(record_to_color(record))
  return nil
}


native_draw_rectangle :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "DRAW-RECTANGLE requires a record with x, y, width, height, color" )
  if err != nil {
    return err
  }

  x := forthic.record_get_int(record, "x", 0)
  y := forthic.record_get_int(record, "y", 0)
  width := forthic.record_get_int(record, "width", 0)
  height := forthic.record_get_int(record, "height", 0)
  color_record := forthic.record_get_record(record, "color", forthic.Record{})

  color := record_to_color(color_record)
  raylib.DrawRectangle(i32(x), i32(y), i32(width), i32(height), color)
  return nil
}

native_draw_text :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "DRAW-TEXT requires a record with text, posX, posY, fontSize, color")
  if err != nil {
    return err
  }

  text := forthic.record_get_string(record, "text", "")
  posX := forthic.record_get_int(record, "posX", 0)
  posY := forthic.record_get_int(record, "posY", 0)
  fontSize := forthic.record_get_int(record, "fontSize", 0)
  color_record := forthic.record_get_record(record, "color", forthic.Record{})

  text_cstring := strings.clone_to_cstring(text)
  defer delete(text_cstring)

  color := record_to_color(color_record)
  raylib.DrawText(text_cstring, i32(posX), i32(posY), i32(fontSize), color)
  return nil
}

// ----------------------------------------------------------------------------
// Support
// ----------------------------------------------------------------------------

record_to_color :: proc(record: forthic.Record) -> raylib.Color {
  return raylib.Color{
    u8(forthic.record_get_int(record, "r", 255)),
    u8(forthic.record_get_int(record, "g", 255)),
    u8(forthic.record_get_int(record, "b", 255)),
    u8(forthic.record_get_int(record, "a", 255)),
  }
}
