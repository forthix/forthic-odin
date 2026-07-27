package forthic

import "core:mem"
import "core:strings"

Module :: struct {
  name: string,
  words: [dynamic]Compiled_Word
}

module_create :: proc(name: string, allocator: mem.Allocator) -> ^Module {
  module := new(Module, allocator)
  module.name = strings.clone(name, allocator)
  module.words = make([dynamic]Compiled_Word, 0, allocator)
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
