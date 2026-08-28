package forthic

import "core:strings"

Module :: struct {
  name: string,
  words: [dynamic]Compiled_Word,

  submodules: map[string]^Module,
  requires_ui_thread: bool,
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
    requires_ui_thread = module.requires_ui_thread,
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

module_find_or_create_submodule :: proc(module: ^Module, name: string) -> ^Module {
  existing_submodule, found := module.submodules[name]
  if found {
    return existing_submodule
  }

  new_submodule := module_create(name)
  module.submodules[name] = new_submodule
  return new_submodule
}
