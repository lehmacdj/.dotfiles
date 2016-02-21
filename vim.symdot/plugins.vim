call plug#begin('~/.vim/plugged')

" General Plugins
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'
Plug 'vim-airline/vim-airline'
Plug 'scrooloose/nerdtree' 
    \| Plug 'Xuyuanp/nerdtree-git-plugin'
    \| Plug 'ivalkeen/nerdtree-execute'
    \| Plug 'ryanoasis/vim-devicons'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-fugitive'
Plug 'scrooloose/syntastic'

" Webdev plugins
Plug 'othree/html5.vim'
Plug 'tpope/vim-surround'
Plug 'cakebaker/scss-syntax.vim'

" Other filetype specific
Plug 'lervag/vimtex'
Plug 'keith/tmux.vim'
Plug 'xu-cheng/brew.vim'
" Plug 'def-lkb/ocp-indent-vim'

" Solarized
Plug 'altercation/vim-colors-solarized'

call plug#end()

" Plugin configuration

" Nerdtree
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }
nnoremap <silent> <Leader>n :NERDTreeToggle<cr>

" Solarized
syntax enable
set background=dark
colorscheme solarized

" vim-devicons
let g:airline_powerline_fonts = 1
