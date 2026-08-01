.PHONY: repl, raylib-repl, raylib-build, raylib-run, test

RAYLIB_BIN := bin/raylib_repl
RAYLIB_SRCS := $(filter-out %_test.odin, $(wildcard forthic/*.odin)) \
               $(wildcard modules/raylib/*.odin) \
               $(wildcard modules/raylib/repl/*.odin)

repl:
	odin run repl

raylib-repl:
	odin run modules/raylib/repl -- modules/raylib/repl/hello.forthic

raylib-build: $(RAYLIB_BIN)

$(RAYLIB_BIN): $(RAYLIB_SRCS)
	mkdir -p bin
	odin build modules/raylib/repl -out:$(RAYLIB_BIN)

raylib-run: $(RAYLIB_BIN)
	./$(RAYLIB_BIN) modules/raylib/repl/hello.forthic

test:
	odin test forthic
