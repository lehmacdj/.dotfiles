syntax on
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab

" Add Pathogen and source plugins
execute pathogen#infect()

" Make backspace behave the way I expect
set backspace=indent,eol,start

" Define the mapleader
let mapleader=","
"
" MARK: map

" Edit the .vimrc
nnoremap <leader>ev :split $MYVIMRC<cr>
" Source the .vimrc
nnoremap <leader>sv :source $MYVIMRC<cr>

" Keybindings for Escape
inoremap jj <esc>
inoremap jk <esc>

" Convenience mappings

" Force save a file
cmap W w !sudo tee % >/dev/null

" Git mappings
nnoremap <leader>gp :w<cr>:!git add % && git commit -m "Updated %" && git push<cr><cr>
nnoremap <leader>gc :w<cr>:!git add % && git commit -m "Updated %"<cr><cr>
nnoremap <leader>gs :!git status<cr>
