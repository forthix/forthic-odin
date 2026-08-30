# forthic-odin

A Forthic interpreter implemented in [Odin](https://odin-lang.org).

## Prerequisites

### Install Odin

**macOS (Homebrew):**
```sh
brew install odin
```

**Other platforms / from source:**
Follow the official install instructions at https://odin-lang.org/docs/install/

Verify the install:
```sh
odin version
```

### Raylib

The raylib-backed words (`modules/raylib`) use Odin's bundled `vendor:raylib` package, which ships prebuilt raylib libraries with the compiler — no separate raylib install is required.

On macOS, if you hit linker errors, make sure the Xcode command line tools are installed:
```sh
xcode-select --install
```

## Building and running

```sh
make repl          # plain Forthic REPL
make raylib-repl    # raylib-backed REPL, runs modules/raylib/repl/hello.forthic
make raylib-build   # builds the raylib REPL binary to bin/raylib_repl
make raylib-run     # builds (if needed) and runs the raylib REPL binary
make test           # run the forthic package test suite
```
