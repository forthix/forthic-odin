package raylib_forthic

import "core:strings"
import "vendor:raylib"
import "../../forthic"

// Set by raylib.LOAD-FONT; DRAW-TEXT falls back to raylib's built-in font
// when no custom font has been loaded.
current_font: raylib.Font
has_custom_font: bool

raylib_module_create :: proc() -> ^forthic.Module {
  raylib_module := forthic.module_create("raylib")

  forthic.module_add_builtin_word(
    raylib_module, "LOAD-FONT", builtin_load_font, "( path:string size:int -- )",
    "Loads a TrueType/OpenType font file at the given pixel size and makes it the font DRAW-TEXT uses.",
    {`"/System/Library/Fonts/SFNSMono.ttf" 16 raylib.LOAD-FONT`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "INIT-WINDOW", builtin_init_window, "( record -- )",
    "Initializes window and OpenGL context. Fields: width (int, default 800), height (int, default 600), title (string, default \"Forthic\").",
    {`{ .width 800 .height 600 .title "Game" } raylib.INIT-WINDOW`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "WINDOW-SHOULD-CLOSE?", builtin_window_should_close, "( -- bool )",
    "Pushes true if the window's close button or ESC has been pressed.",
    {"raylib.WINDOW-SHOULD-CLOSE?"},
  )
  forthic.module_add_builtin_word(
    raylib_module, "CLOSE-WINDOW", builtin_close_window, "( -- )",
    "Closes window and unloads OpenGL context.",
    {"raylib.CLOSE-WINDOW"},
  )

  forthic.module_add_builtin_word(
    raylib_module, "BEGIN-DRAWING", builtin_begin_drawing, "( -- )",
    "Set up canvas to start drawing.",
    {"raylib.BEGIN-DRAWING"},
  )
  forthic.module_add_builtin_word(
    raylib_module, "CLEAR-BACKGROUND", builtin_clear_background, "( record -- )",
    "Clears the background with the given color. Fields: r, g, b, a (int 0-255, each defaults to 255).",
    {`{ .r 245 .g 245 .b 245 .a 255 } raylib.CLEAR-BACKGROUND`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "DRAW-RECTANGLE", builtin_draw_rectangle, "( record -- )",
    "Draws a color-filled rectangle. Fields: x, y, width, height (int, default 0), color (record with r, g, b, a, default all 255).",
    {`{ .x 10 .y 10 .width 100 .height 50 .color { .r 255 .g 0 .b 0 .a 255 } } raylib.DRAW-RECTANGLE`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "DRAW-TEXT", builtin_draw_text, "( record -- )",
    "Draws text using the default font. Fields: text (string, default \"\"), posX, posY (int, default 0), fontSize (int, default 0), color (record with r, g, b, a, default all 255).",
    {`{ .text "Hello" .posX 10 .posY 10 .fontSize 20 .color { .r 0 .g 0 .b 0 .a 255 } } raylib.DRAW-TEXT`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "END-DRAWING", builtin_end_drawing, "( -- )",
    "End canvas drawing and swap buffers.",
    {"raylib.END-DRAWING"},
  )

  forthic.module_add_builtin_word(
    raylib_module, "BEGIN-MODE-3D", builtin_begin_mode_3d, "( record -- )",
    "Begins 3D mode with a camera. Fields: position, target, up (each a record with x, y, z; up defaults to {0,1,0}), fovy (number, default 60).",
    {`{ .position { .x 0 .y 1 .z 0 } .target { .x 0 .y 1 .z -1 } } raylib.BEGIN-MODE-3D`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "END-MODE-3D", builtin_end_mode_3d, "( -- )",
    "Ends 3D mode and returns to default 2D orthographic mode.",
    {"raylib.END-MODE-3D"},
  )
  forthic.module_add_builtin_word(
    raylib_module, "DRAW-CUBE", builtin_draw_cube, "( record -- )",
    "Draws a color-filled cube. Fields: x, y, z (number, default 0), width, height, length (number, default 0), color (record with r, g, b, a, default all 255).",
    {`{ .x 0 .y 0.5 .z 0 .width 1 .height 1 .length 1 .color { .r 200 .g 50 .b 50 .a 255 } } raylib.DRAW-CUBE`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "DRAW-GRID", builtin_draw_grid, "( record -- )",
    "Draws a grid centered at the origin, for use as a floor reference. Fields: slices (int, default 10), spacing (number, default 1).",
    {`{ .slices 20 .spacing 1 } raylib.DRAW-GRID`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "IS-KEY-DOWN", builtin_is_key_down, "( key:string -- bool )",
    "Returns true while the named key is held down. Recognized names: W A S D UP DOWN LEFT RIGHT ESCAPE.",
    {`"W" raylib.IS-KEY-DOWN`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "IS-KEY-PRESSED", builtin_is_key_pressed, "( key:string -- bool )",
    "Returns true only on the frame the named key transitions from up to down (edge-triggered, unlike IS-KEY-DOWN). Recognized names: W A S D UP DOWN LEFT RIGHT ESCAPE.",
    {`"W" raylib.IS-KEY-PRESSED`},
  )
  forthic.module_add_builtin_word(
    raylib_module, "SET-TARGET-FPS", builtin_set_target_fps, "( fps:int -- )",
    "Caps the frame rate.",
    {"60 raylib.SET-TARGET-FPS"},
  )

  return raylib_module
}

// ( -- )
builtin_close_window :: proc(_: ^forthic.Interpreter) -> forthic.Error {
  raylib.CloseWindow()
  return nil
}

// ( record -- )
builtin_init_window :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "INIT-WINDOW requires a record with width, height, and title")
  if err != nil {
    return err
  }

  width := forthic.record_get_int(record, "width", 800)
  height := forthic.record_get_int(record, "height", 600)
  title := forthic.record_get_string(record, "title", "Forthic")

  title_cstr := strings.clone_to_cstring(title)
  defer delete(title_cstr)
  raylib.InitWindow(i32(width), i32(height), title_cstr)
  return nil
}

// ( -- bool )
builtin_window_should_close :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  should_close := raylib.WindowShouldClose()
  forthic.stack_push(&interp.stack, forthic.Forthic_Value(should_close))
  return nil
}

// ( -- )
builtin_begin_drawing :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  raylib.BeginDrawing()
  return nil
}

// ( -- )
builtin_end_drawing :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  raylib.EndDrawing()
  return nil
}


// ( record -- )
builtin_clear_background :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "CLEAR-BACKGROUND requires a record with r, g, b, a" )
  if err != nil {
    return err
  }

  raylib.ClearBackground(record_to_color(record))
  return nil
}


// ( record -- )
builtin_draw_rectangle :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "DRAW-RECTANGLE requires a record with x, y, width, height, color" )
  if err != nil {
    return err
  }

  x := record_get_f32(record, "x", 0)
  y := record_get_f32(record, "y", 0)
  width := record_get_f32(record, "width", 0)
  height := record_get_f32(record, "height", 0)
  color_record := forthic.record_get_record(record, "color", forthic.Record{})

  color := record_to_color(color_record)
  raylib.DrawRectangle(i32(x), i32(y), i32(width), i32(height), color)
  return nil
}

// ( path:string size:int -- )
builtin_load_font :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  size, size_err := forthic.pop_int(interp, "LOAD-FONT")
  if size_err != nil {
    return size_err
  }
  path, path_err := forthic.pop_string(interp, "LOAD-FONT")
  if path_err != nil {
    return path_err
  }

  if has_custom_font {
    raylib.UnloadFont(current_font)
  }

  path_cstring := strings.clone_to_cstring(path)
  defer delete(path_cstring)

  current_font = raylib.LoadFontEx(path_cstring, i32(size), nil, 0)
  has_custom_font = true
  return nil
}

// ( record -- )
builtin_draw_text :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "DRAW-TEXT requires a record with text, posX, posY, fontSize, color")
  if err != nil {
    return err
  }

  text := forthic.record_get_string(record, "text", "")
  posX := record_get_f32(record, "posX", 0)
  posY := record_get_f32(record, "posY", 0)
  fontSize := record_get_f32(record, "fontSize", 0)
  color_record := forthic.record_get_record(record, "color", forthic.Record{})

  text_cstring := strings.clone_to_cstring(text)
  defer delete(text_cstring)

  color := record_to_color(color_record)
  font := has_custom_font ? current_font : raylib.GetFontDefault()
  raylib.DrawTextEx(font, text_cstring, raylib.Vector2{posX, posY}, fontSize, fontSize * 0.1, color)
  return nil
}

// ( record -- )
builtin_begin_mode_3d :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "BEGIN-MODE-3D requires a record with position, target, up, fovy")
  if err != nil {
    return err
  }

  position_record := forthic.record_get_record(record, "position", forthic.Record{})
  target_record := forthic.record_get_record(record, "target", forthic.Record{})
  up_record := forthic.record_get_record(record, "up", forthic.Record{})

  camera := raylib.Camera3D{
    position   = record_to_vector3(position_record, raylib.Vector3{0, 0, 0}),
    target     = record_to_vector3(target_record, raylib.Vector3{0, 0, -1}),
    up         = record_to_vector3(up_record, raylib.Vector3{0, 1, 0}),
    fovy       = record_get_f32(record, "fovy", 60.0),
    projection = .PERSPECTIVE,
  }
  raylib.BeginMode3D(camera)
  return nil
}

// ( -- )
builtin_end_mode_3d :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  raylib.EndMode3D()
  return nil
}

// ( record -- )
builtin_draw_cube :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "DRAW-CUBE requires a record with x, y, z, width, height, length, color")
  if err != nil {
    return err
  }

  x := record_get_f32(record, "x", 0)
  y := record_get_f32(record, "y", 0)
  z := record_get_f32(record, "z", 0)
  width := record_get_f32(record, "width", 0)
  height := record_get_f32(record, "height", 0)
  length := record_get_f32(record, "length", 0)
  color_record := forthic.record_get_record(record, "color", forthic.Record{})

  raylib.DrawCube(raylib.Vector3{x, y, z}, width, height, length, record_to_color(color_record))
  return nil
}

// ( record -- )
builtin_draw_grid :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  record, err := forthic.stack_pop_record(&interp.stack, "DRAW-GRID requires a record with slices, spacing")
  if err != nil {
    return err
  }

  slices := forthic.record_get_int(record, "slices", 10)
  spacing := record_get_f32(record, "spacing", 1.0)

  raylib.DrawGrid(i32(slices), spacing)
  return nil
}

// ( key:string -- bool )
builtin_is_key_down :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  key_name, err := forthic.pop_string(interp, "IS-KEY-DOWN")
  if err != nil {
    return err
  }

  key, found := key_from_name(key_name)
  if !found {
    return forthic.Type_Mismatch{note = "IS-KEY-DOWN: unrecognized key name"}
  }

  forthic.stack_push(&interp.stack, forthic.Forthic_Value(bool(raylib.IsKeyDown(key))))
  return nil
}

// ( key:string -- bool )
builtin_is_key_pressed :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  key_name, err := forthic.pop_string(interp, "IS-KEY-PRESSED")
  if err != nil {
    return err
  }

  key, found := key_from_name(key_name)
  if !found {
    return forthic.Type_Mismatch{note = "IS-KEY-PRESSED: unrecognized key name"}
  }

  forthic.stack_push(&interp.stack, forthic.Forthic_Value(bool(raylib.IsKeyPressed(key))))
  return nil
}

// ( fps:int -- )
builtin_set_target_fps :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  fps, err := forthic.pop_int(interp, "SET-TARGET-FPS")
  if err != nil {
    return err
  }

  raylib.SetTargetFPS(i32(fps))
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

// Tolerates both int and float literals for a numeric record field, unlike
// forthic.record_get_float which requires an exact f64 match.
record_get_f32 :: proc(record: forthic.Record, name: string, default: f32) -> f32 {
  value, present := record[forthic.Dot_Symbol(name)]
  if !present {
    return default
  }
  as_float, ok := forthic.forthic_value_as_f64(value)
  if !ok {
    return default
  }
  return f32(as_float)
}

record_to_vector3 :: proc(record: forthic.Record, default: raylib.Vector3) -> raylib.Vector3 {
  return raylib.Vector3{
    record_get_f32(record, "x", default.x),
    record_get_f32(record, "y", default.y),
    record_get_f32(record, "z", default.z),
  }
}

key_from_name :: proc(name: string) -> (raylib.KeyboardKey, bool) {
  switch name {
  case "W": return .W, true
  case "A": return .A, true
  case "S": return .S, true
  case "D": return .D, true
  case "UP": return .UP, true
  case "DOWN": return .DOWN, true
  case "LEFT": return .LEFT, true
  case "RIGHT": return .RIGHT, true
  case "ESCAPE": return .ESCAPE, true
  case: return .KEY_NULL, false
  }
}
