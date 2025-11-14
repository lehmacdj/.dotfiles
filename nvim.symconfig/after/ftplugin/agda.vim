nnoremap <buffer> <LocalLeader>l <Cmd>CornelisLoad<CR>
nnoremap <buffer> <LocalLeader>r <Cmd>CornelisRefine<CR>
nnoremap <buffer> <LocalLeader>c <Cmd>CornelisMakeCase<CR>
nnoremap <buffer> <LocalLeader>, <Cmd>CornelisTypeContext<CR>
nnoremap <buffer> <LocalLeader>n <Cmd>CornelisSolve<CR>
nnoremap <buffer> <LocalLeader>a <Cmd>CornelisAuto<CR>
nnoremap <buffer> gd <Cmd>CornelisGoToDefinition<CR>
nnoremap <buffer> [/ <Cmd>CornelisPrevGoal<CR>
nnoremap <buffer> ]/ <Cmd>CornelisNextGoal<CR>

augroup CornelisAutoLoad
  autocmd!
  autocmd BufWritePost *.agda,*.lagda execute "normal! :CornelisLoad\<CR>"
augroup END
