.PHONY: repl, raylib-repl, raylib-build, raylib-run, test

repl:
	odin run repl

raylib-repl:
	odin run modules/raylib/repl -- modules/raylib/repl/hello.forthic

raylib-build:
	mkdir -p bin
	odin build modules/raylib/repl -out:bin/raylib_repl

raylib-run:
	./bin/raylib_repl modules/raylib/repl/hello.forthic

test:
	odin test forthic
