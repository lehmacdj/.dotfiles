nnoremap <LocalLeader>m :!make %:r<CR>
nnoremap <LocalLeader>r :!./%:r<CR>
nnoremap <LocalLeader>d :!valgrind --track-origins=yes ./%:r<CR>

setlocal tabstop=2
setlocal shiftwidth=2
