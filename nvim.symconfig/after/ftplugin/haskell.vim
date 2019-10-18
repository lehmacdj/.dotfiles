let g:haskell_indent_case_alternative = 1
let g:haskell_enable_quantification = 1
let g:haskell_enable_pattern_synonyms = 1

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
