let g:necoghc_enable_detailed_browse = 1
let g:haskell_indent_case_alternative = 1

autocmd BufWritePost *.hs InteroReload

map <LocalLeader>t <Plug>InteroGenericType
map <LocalLeader>T <Plug>InteroType
nnoremap <LocalLeader>it :InteroTypeInsert<CR>
nnoremap <LocalLeader>oi :InteroOpen<CR>

nnoremap <LocalLeader>gd :InteroGoToDef<CR>
