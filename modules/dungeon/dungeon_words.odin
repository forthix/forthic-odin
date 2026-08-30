package dungeon_forthic

import "../../forthic"

dungeon_module_create :: proc() -> ^forthic.Module {
  dungeon_module := forthic.module_create("dungeon")

  forthic.module_add_builtin_word(
    dungeon_module, "IS-WALL?", builtin_is_wall, "( dungeon:array x:int y:int -- bool )",
    "Checks a dungeon grid cell. dungeon is an array of equal-length row strings ('#' = wall, anything else = floor). Out-of-bounds cells count as walls.",
    {`dungeon 3 2 dungeon.IS-WALL?`},
  )

  return dungeon_module
}

// ( dungeon:array x:int y:int -- bool )
builtin_is_wall :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  y, y_err := forthic.pop_int(interp, "IS-WALL?")
  if y_err != nil {
    return y_err
  }
  x, x_err := forthic.pop_int(interp, "IS-WALL?")
  if x_err != nil {
    return x_err
  }
  dungeon, dungeon_err := forthic.pop_array(interp, "IS-WALL?")
  if dungeon_err != nil {
    return dungeon_err
  }

  is_wall := true
  if y >= 0 && int(y) < len(dungeon) {
    row_val, row_ok := dungeon[y].(string)
    if row_ok && x >= 0 && int(x) < len(row_val) {
      is_wall = row_val[x] == '#'
    }
  }

  forthic.stack_push(&interp.stack, forthic.Forthic_Value(is_wall))
  return nil
}
