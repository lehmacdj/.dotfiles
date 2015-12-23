" Configure vundle first
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Other plugins
Plugin 'tpope/vim-sensible'
Plugin 'xu-cheng/brew.vim'
Plugin 'lervag/vimtex'

call vundle#end()
" see :h vundle for more details or wiki for FAQ
" End vundle configuration

filetype plugin indent on
syntax on
set tabstop=4
set shiftwidth=4
set expandtab

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
