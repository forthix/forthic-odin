package forthic

import "core:strings"

Module :: struct {
  name: string,
  words: [dynamic]Compiled_Word
}

module_create :: proc(name: string) -> ^Module {
  module := new(Module)
  module.name = strings.clone(name)
  module.words = make([dynamic]Compiled_Word, 0)
  return module
}

module_find_word :: proc(module: ^Module, name: string) -> (Compiled_Word, bool) {
 #reverse  for word in module.words {
   if word.name == name {
     return word, true
   }
 }
 return {}, false
}
