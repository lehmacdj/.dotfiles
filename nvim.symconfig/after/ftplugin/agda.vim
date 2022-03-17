nnoremap <buffer> <LocalLeader>l :CornelisLoad<CR>
nnoremap <buffer> <LocalLeader>r :CornelisRefine<CR>
nnoremap <buffer> <LocalLeader>c :CornelisMakeCase<CR>
nnoremap <buffer> <LocalLeader>, :CornelisTypeContext<CR>
nnoremap <buffer> <LocalLeader>n :CornelisSolve<CR>
nnoremap <buffer> <LocalLeader>a :CornelisAuto<CR>
nnoremap <buffer> gd :CornelisGoToDefinition<CR>
nnoremap <buffer> [/ :CornelisPrevGoal<CR>
nnoremap <buffer> ]/ :CornelisNextGoal<CR>

augroup CornelisAutoLoad
  autocmd!
  autocmd BufWritePost *.agda,*.lagda execute "normal! :CornelisLoad\<CR>"
augroup END
