package forthic

Module :: struct {
  name: string,
  words: [dynamic]Compiled_Word
}

module_find_word :: proc(module: ^Module, name: string) -> (Compiled_Word, bool) {
 #reverse  for word in module.words {
   if word.name == name {
     return word, true
   }
 }
 return {}, false
}

module_destroy :: proc(module: ^Module) {
  delete(module.words)
  free(module)
}
