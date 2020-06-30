" weird changes directly to plugins manifest:
" - changed neomake linters to not use stack when finding executable
"   because hlint didn't support the most recent version

let g:haskell_indent_case_alternative = 1
let g:haskell_enable_quantification = 1
let g:haskell_enable_pattern_synonyms = 1

let g:ormolu_command='/nix/store/q9gbpjx6mj43ramii1zl8s8jp5qirraw-ormolu-0.1.0.0/bin/ormolu'
let g:ormolu_options=["-o -XTypeApplications"]
