augroup ghccore_filetype_detect
  autocmd!
  autocmd BufRead,BufNewFile *.dump-prep,*.dump-simpl setfiletype ghccore
augroup END
