if exists("b:current_syntax")
  finish
endif

let b:current_syntax = "coa"

syntax keyword aocKeyword fn over for in as end return if elif else do then
highlight link aocKeyword Keyword

syntax keyword aocFunction print read_file_lines to_int split range
highlight link aocFunction Function

syntax match aocComment "#.*$"
highlight link aocComment Comment

syntax match aocString /".*"/
highlight link aocString String

syntax match aocNumber /\v\d+/
highlight link aocNumber Number

