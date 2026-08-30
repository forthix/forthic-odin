package sqlite_forthic

import "core:c"

// Minimal hand-written binding to the system libsqlite3 -- no vendor:sqlite3
// package exists for this Odin install. macOS ships libsqlite3 system-wide;
// this follows the same "system:" linking pattern vendor/zlib uses on Darwin.
foreign import sqlite3 "system:sqlite3"

DB :: struct {}
Stmt :: struct {}

SQLITE_OK :: 0
SQLITE_ROW :: 100
SQLITE_DONE :: 101

SQLITE_INTEGER :: 1
SQLITE_FLOAT :: 2
SQLITE_TEXT :: 3
SQLITE_BLOB :: 4
SQLITE_NULL :: 5

// SQLITE_TRANSIENT: tells sqlite3 to make its own internal copy of bound
// text immediately, so the cstring we pass can be freed right after the
// bind call instead of having to outlive the statement.
SQLITE_TRANSIENT :: rawptr(~uintptr(0))

@(default_calling_convention = "c")
foreign sqlite3 {
  sqlite3_open :: proc(filename: cstring, db: ^^DB) -> c.int ---
  sqlite3_close :: proc(db: ^DB) -> c.int ---
  sqlite3_exec :: proc(db: ^DB, sql: cstring, callback: rawptr, arg: rawptr, errmsg: ^cstring) -> c.int ---
  sqlite3_prepare_v2 :: proc(db: ^DB, sql: cstring, n_byte: c.int, stmt: ^^Stmt, tail: ^cstring) -> c.int ---
  sqlite3_step :: proc(stmt: ^Stmt) -> c.int ---
  sqlite3_finalize :: proc(stmt: ^Stmt) -> c.int ---
  sqlite3_bind_text :: proc(stmt: ^Stmt, idx: c.int, val: cstring, n: c.int, destructor: rawptr) -> c.int ---
  sqlite3_bind_int64 :: proc(stmt: ^Stmt, idx: c.int, val: i64) -> c.int ---
  sqlite3_bind_null :: proc(stmt: ^Stmt, idx: c.int) -> c.int ---
  sqlite3_bind_double :: proc(stmt: ^Stmt, idx: c.int, val: f64) -> c.int ---
  sqlite3_column_count :: proc(stmt: ^Stmt) -> c.int ---
  sqlite3_column_name :: proc(stmt: ^Stmt, col: c.int) -> cstring ---
  sqlite3_column_type :: proc(stmt: ^Stmt, col: c.int) -> c.int ---
  sqlite3_column_int64 :: proc(stmt: ^Stmt, col: c.int) -> i64 ---
  sqlite3_column_double :: proc(stmt: ^Stmt, col: c.int) -> f64 ---
  sqlite3_column_text :: proc(stmt: ^Stmt, col: c.int) -> cstring ---
  sqlite3_last_insert_rowid :: proc(db: ^DB) -> i64 ---
  sqlite3_errmsg :: proc(db: ^DB) -> cstring ---
}
