package forthic

import "core:strings"

Module :: struct {
  name: string,
  words: [dynamic]Compiled_Word,

  submodules: map[string]^Module,
  variables: map[string]Forthic_Value,
}

module_create :: proc(name: string) -> ^Module {
  module := new(Module)
  module.name = strings.clone(name)
  module.words = make([dynamic]Compiled_Word, 0)
  return module
}

module_add_word :: proc(module: ^Module, word: Compiled_Word) {
  append(&module.words, word)
}

module_add_builtin_word :: proc(
  module: ^Module, 
  name: string,
  handler: Builtin_Word_Proc,
  stack_effect: string,
  description: string,
  examples: []string,
) {
  module_add_word(module, Compiled_Word{
    name = strings.clone(name),
    action = Builtin_Word_Proc(handler),
    doc = Word_Doc{
      stack_effect = stack_effect,
      description = description,
      examples = examples,
    },
  })
}

module_find_word :: proc(module: ^Module, name: string) -> (Compiled_Word, bool) {
 #reverse  for word in module.words {
   if word.name == name {
     return word, true
   }
 }
 return {}, false
}

module_import_words :: proc(dest: ^Module, src: ^Module) {
  for word in src.words {
    module_add_word(dest, word)
  }
}

module_import_words_prefixed :: proc(dest: ^Module, src: ^Module, prefix: string) {
  for word in src.words {
    prefixed_word := word
    prefixed_word.name = strings.concatenate({prefix, ".", word.name})
    module_add_word(dest, prefixed_word)
  }
}

// Builds a module with one forwarding word per word in source: calling a
// mirror word runs the real word on target via queue instead of locally.
// Lets a REPL-owned interpreter compose words that actually execute on
// another interpreter (e.g. one pinned to a UI thread) without knowing
// anything about the hand-off.
//
// target_prefix must be whatever prefix source was (or will be) registered
// under on target via interpreter_register_and_import_module -- that's the
// only name each real word is actually findable under when a job drains
// against target's own module_stack, since source's own words stay
// unprefixed (module_import_words_prefixed copies renamed words into
// target's app module; it doesn't rename source's words in place).
module_mirror :: proc(source: ^Module, target: ^Interpreter, target_prefix: string, queue: ^Mirror_Job_Queue) -> ^Module {
  mirror := module_create(source.name)
  for word in source.words {
    mirror_word := word
    mirror_word.action = Mirror_Action{
      word_name = strings.concatenate({target_prefix, ".", word.name}),
      target = target,
      queue = queue,
    }
    module_add_word(mirror, mirror_word)
  }
  return mirror
}

module_find_or_create_submodule :: proc(module: ^Module, name: string) -> ^Module {
  existing_submodule, found := module.submodules[name]
  if found {
    return existing_submodule
  }

  new_submodule := module_create(name)
  module.submodules[name] = new_submodule
  return new_submodule
}

// Compiles filename's word definitions into a fresh module, using interp
// (already-registered modules and core words) for lookups during
// compilation -- e.g. a bareword reference like sqlite.EXEC resolves
// correctly as long as sqlite is already registered on interp. Runs on an
// isolated scratch stack (see run_file_isolated, control_words.odin);
// filename must leave it empty -- it's a library of definitions, not a
// value, same contract LOAD-OBJECT uses for data files.
module_create_from_forthic_file :: proc(interp: ^Interpreter, name: string, filename: string) -> (^Module, Error) {
  temp_module := module_create(name)
  append(&interp.module_stack, temp_module)
  defer pop(&interp.module_stack)

  loaded_stack, run_err := run_file_isolated(interp, filename)
  defer stack_destroy(&loaded_stack)

  if run_err != nil {
    return nil, run_err
  }
  if stack_len(&loaded_stack) != 0 {
    return nil, Type_Mismatch{note = "module_create_from_forthic_file requires the file to leave the stack empty"}
  }
  return temp_module, nil
}
