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
module_mirror :: proc(source: ^Module, target: ^Interpreter, queue: ^Mirror_Job_Queue) -> ^Module {
  mirror := module_create(source.name)
  for word in source.words {
    mirror_word := word
    mirror_word.action = Mirror_Action{word_name = word.name, target = target, queue = queue}
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
