let g:haskell_indent_case_alternative = 1
let g:haskell_enable_quantification = 1

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

map <LocalLeader>t <Plug>InteroGenericType
map <LocalLeader>T <Plug>InteroType
nnoremap <LocalLeader>it :InteroTypeInsert<CR>

" manage intero repl
nnoremap <LocalLeader>o :InteroOpen<CR>
nnoremap <LocalLeader>ir :InteroRestart<CR>
nnoremap <LocalLeader>i3 :InteroSetTargets lib test<CR>
nnoremap <LocalLeader>lf :InteroLoadCurrentFile<CR>
" sometime intero messes up
nnoremap <LocalLeader>r :InteroReload<CR>

nnoremap gd :InteroGoToDef<CR>

set sw=2
set ts=2
