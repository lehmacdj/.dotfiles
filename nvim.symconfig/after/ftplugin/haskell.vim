" weird changes directly to plugins manifest:
" - changed neomake linters to not use stack when finding executable
"   because hlint didn't support the most recent version

let g:haskell_indent_case_alternative = 1
let g:haskell_enable_quantification = 1
let g:haskell_enable_pattern_synonyms = 1
" let g:haskell_indent_disable = 1

let g:ormolu_command='/nix/store/q9gbpjx6mj43ramii1zl8s8jp5qirraw-ormolu-0.1.0.0/bin/ormolu'
let g:ormolu_options=["-o -XTypeApplications"]

function! s:intero_exe(command) abort
    if !g:intero_started
        echoerr 'Intero is still starting up'
    else
        exe a:command
    endif
endfunction

augroup devin-haskell
    autocmd!
    if len(systemlist('stack ide packages')) == 0
        autocmd BufEnter <buffer> call s:intero_exe("InteroLoadCurrentFile")
    endif
    autocmd BufWritePost <buffer> call s:intero_exe("InteroReload")
augroup END

map <buffer> <LocalLeader>t <Plug>InteroGenericType
map <buffer> <LocalLeader>T <Plug>InteroType
nnoremap <buffer> <LocalLeader>it :InteroTypeInsert<CR>

" manage intero repl
nnoremap <buffer> <LocalLeader>o :InteroOpen<CR>
nnoremap <buffer> <LocalLeader>ir :InteroRestart<CR>
nnoremap <buffer> <LocalLeader>i3 :InteroSetTargets lib test<CR>
nnoremap <buffer> <LocalLeader>lf :InteroLoadCurrentFile<CR>
" sometime intero messes up
nnoremap <buffer> <LocalLeader>r :InteroReload<CR>

nnoremap <buffer> gd :InteroGoToDef<CR>
nnoremap <buffer> <LocalLeader>d :InteroGoToDef<CR>
