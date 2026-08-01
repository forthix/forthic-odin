package raylib_forthic

import "core:strings"
import "vendor:raylib"
import "../../forthic"

raylib_module_create :: proc() -> ^forthic.Module {
  raylib_module := forthic.module_create("raylib")

  forthic.module_add_native_word(raylib_module, "CLOSE-WINDOW", native_close_window, "( -- )", "Closes window and unloads OpenGL context", {})
  forthic.module_add_native_word(raylib_module, "INIT-WINDOW", native_init_window, "( record -- )", "Initializes window and OpenGL context", {})
  forthic.module_add_native_word(raylib_module, "WINDOW-SHOULD-CLOSE?", native_window_should_close, "( -- )", "Check if window should close", {})
  forthic.module_add_native_word(raylib_module, "BEGIN-DRAWING", native_begin_drawing, "( -- )", "Set up canvas to start drawing", {})
  forthic.module_add_native_word(raylib_module, "END-DRAWING", native_end_drawing, "( -- )", "End canvas drawing and swap buffers", {})
  forthic.module_add_native_word(raylib_module, "CLEAR-BACKGROUND", native_clear_background, "( color -- )", "Sets background color", {})

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
  value, err := forthic.stack_pop(&interp.stack)
  if err != nil {
    return err
  }

  record, is_record := value.(forthic.Record)
  if !is_record {
    return forthic.Type_Mismatch{ note = "CLEAR-BACKGROUND requires a record with r, g, b, a" }
  }

  raylib.ClearBackground(record_to_color(record))
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
