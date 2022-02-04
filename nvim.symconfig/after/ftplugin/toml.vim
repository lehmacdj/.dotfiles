" auto rebuild the starship template when writing template.starship.toml
" see note in $DOTFILES/starship/template.starship.toml
augroup template.starship.toml
    autocmd!
    autocmd BufWritePost template.starship.toml
        \ call system($DOTFILES . '/starship/build-starship.sh')
augroup END
