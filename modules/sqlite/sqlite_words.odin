package sqlite_forthic

import "core:c"
import "core:strings"
import "../../forthic"

// General-purpose SQLite access -- domain-agnostic on purpose. Every word's
// stack in/out is built only from plain Forthic_Value types (string, i64,
// f64, bool, array, record, nil): no opaque handle (the connection itself)
// ever touches the stack. That keeps every word here safe to later expose
// through a JSON-RPC server too, unchanged, the same way forthic-ts exposes
// its own words remotely.
db: ^DB

sqlite_module_create :: proc() -> ^forthic.Module {
  sqlite_module := forthic.module_create("sqlite")

  forthic.module_add_builtin_word(
    sqlite_module, "OPEN", builtin_sqlite_open, "( path:string -- )",
    "Opens (creating if needed) a SQLite database file.",
    {`"dungeon_history.db" sqlite.OPEN`},
  )
  forthic.module_add_builtin_word(
    sqlite_module, "EXEC", builtin_sqlite_exec, "( sql:string -- )",
    "Runs a SQL statement with no bound parameters and no result set (schema DDL, etc).",
    {`"CREATE TABLE IF NOT EXISTS t (id INTEGER PRIMARY KEY)" sqlite.EXEC`},
  )
  forthic.module_add_builtin_word(
    sqlite_module, "EXEC-WITH", builtin_sqlite_exec_with, "( sql:string params:array -- )",
    "Runs a SQL statement, binding params positionally to '?' placeholders. For INSERT/UPDATE/DELETE.",
    {`"INSERT INTO t (id) VALUES (?)" [ 1 ] sqlite.EXEC-WITH`},
  )
  forthic.module_add_builtin_word(
    sqlite_module, "QUERY-WITH", builtin_sqlite_query_with, "( sql:string params:array -- rows:array )",
    "Runs a parameterized SELECT. Each row becomes a record keyed by column name.",
    {`"SELECT id FROM t WHERE id = ?" [ 1 ] sqlite.QUERY-WITH`},
  )
  forthic.module_add_builtin_word(
    sqlite_module, "LAST-INSERT-ID", builtin_sqlite_last_insert_id, "( -- id:int )",
    "The rowid of the most recent successful INSERT.",
    {"sqlite.LAST-INSERT-ID"},
  )

  return sqlite_module
}

// ( path:string -- )
builtin_sqlite_open :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  path, err := forthic.pop_string(interp, "sqlite.OPEN")
  if err != nil {
    return err
  }

  path_cstring := strings.clone_to_cstring(path)
  defer delete(path_cstring)

  rc := sqlite3_open(path_cstring, &db)
  if rc != SQLITE_OK {
    return forthic.Type_Mismatch{note = "sqlite.OPEN failed to open database"}
  }
  return nil
}

// ( sql:string -- )
builtin_sqlite_exec :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  sql, err := forthic.pop_string(interp, "sqlite.EXEC")
  if err != nil {
    return err
  }

  sql_cstring := strings.clone_to_cstring(sql)
  defer delete(sql_cstring)

  errmsg: cstring
  rc := sqlite3_exec(db, sql_cstring, nil, nil, &errmsg)
  if rc != SQLITE_OK {
    return forthic.Type_Mismatch{note = sqlite_error_note("sqlite.EXEC", errmsg)}
  }
  return nil
}

// ( sql:string params:array -- )
builtin_sqlite_exec_with :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  stmt, sql_err := prepare_with_params(interp, "sqlite.EXEC-WITH")
  if sql_err != nil {
    return sql_err
  }
  defer sqlite3_finalize(stmt)

  rc := sqlite3_step(stmt)
  if rc != SQLITE_DONE {
    return forthic.Type_Mismatch{note = sqlite_error_note("sqlite.EXEC-WITH", sqlite3_errmsg(db))}
  }
  return nil
}

// ( sql:string params:array -- rows:array )
builtin_sqlite_query_with :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  stmt, sql_err := prepare_with_params(interp, "sqlite.QUERY-WITH")
  if sql_err != nil {
    return sql_err
  }
  defer sqlite3_finalize(stmt)

  col_count := int(sqlite3_column_count(stmt))
  col_names := make([]string, col_count)
  for i in 0 ..< col_count {
    col_names[i] = strings.clone_from_cstring(sqlite3_column_name(stmt, c.int(i)))
  }

  rows := make([dynamic]forthic.Forthic_Value, 0)
  for {
    rc := sqlite3_step(stmt)
    if rc == SQLITE_DONE {
      break
    }
    if rc != SQLITE_ROW {
      return forthic.Type_Mismatch{note = sqlite_error_note("sqlite.QUERY-WITH", sqlite3_errmsg(db))}
    }

    row := make(forthic.Record)
    for i in 0 ..< col_count {
      row[forthic.Dot_Symbol(col_names[i])] = column_value(stmt, c.int(i))
    }
    append(&rows, forthic.Forthic_Value(row))
  }

  forthic.stack_push(&interp.stack, forthic.Forthic_Value(rows))
  return nil
}

// ( -- id:int )
builtin_sqlite_last_insert_id :: proc(interp: ^forthic.Interpreter) -> forthic.Error {
  forthic.stack_push(&interp.stack, forthic.Forthic_Value(i64(sqlite3_last_insert_rowid(db))))
  return nil
}

// ----------------------------------------------------------------------------
// Support
// ----------------------------------------------------------------------------

prepare_with_params :: proc(interp: ^forthic.Interpreter, word_name: string) -> (^Stmt, forthic.Error) {
  params, params_err := forthic.pop_array(interp, word_name)
  if params_err != nil {
    return nil, params_err
  }
  sql, sql_err := forthic.pop_string(interp, word_name)
  if sql_err != nil {
    return nil, sql_err
  }

  sql_cstring := strings.clone_to_cstring(sql)
  defer delete(sql_cstring)

  stmt: ^Stmt
  rc := sqlite3_prepare_v2(db, sql_cstring, -1, &stmt, nil)
  if rc != SQLITE_OK {
    return nil, forthic.Type_Mismatch{note = sqlite_error_note(word_name, sqlite3_errmsg(db))}
  }

  for param, i in params {
    bind_err := bind_param(stmt, c.int(i + 1), param)
    if bind_err != nil {
      sqlite3_finalize(stmt)
      return nil, bind_err
    }
  }

  return stmt, nil
}

bind_param :: proc(stmt: ^Stmt, idx: c.int, value: forthic.Forthic_Value) -> forthic.Error {
  if value == nil {
    sqlite3_bind_null(stmt, idx)
    return nil
  }
  switch v in value {
  case i64:
    sqlite3_bind_int64(stmt, idx, v)
  case f64:
    sqlite3_bind_double(stmt, idx, v)
  case bool:
    sqlite3_bind_int64(stmt, idx, v ? 1 : 0)
  case string:
    text_cstring := strings.clone_to_cstring(v)
    defer delete(text_cstring)
    sqlite3_bind_text(stmt, idx, text_cstring, -1, SQLITE_TRANSIENT)
  case forthic.Dot_Symbol:
    text_cstring := strings.clone_to_cstring(string(v))
    defer delete(text_cstring)
    sqlite3_bind_text(stmt, idx, text_cstring, -1, SQLITE_TRANSIENT)
  case forthic.Record, [dynamic]forthic.Forthic_Value:
    return forthic.Type_Mismatch{note = "sqlite params must be scalars (records/arrays are not bindable)"}
  }
  return nil
}

column_value :: proc(stmt: ^Stmt, col: c.int) -> forthic.Forthic_Value {
  switch sqlite3_column_type(stmt, col) {
  case SQLITE_INTEGER:
    return forthic.Forthic_Value(sqlite3_column_int64(stmt, col))
  case SQLITE_FLOAT:
    return forthic.Forthic_Value(sqlite3_column_double(stmt, col))
  case SQLITE_TEXT:
    return forthic.Forthic_Value(strings.clone_from_cstring(sqlite3_column_text(stmt, col)))
  case:
    return nil
  }
}

sqlite_error_note :: proc(word_name: string, errmsg: cstring) -> string {
  msg := errmsg != nil ? string(errmsg) : "unknown error"
  return strings.concatenate({word_name, ": ", msg})
}
