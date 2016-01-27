call plug#begin('~/.vim/plugged')

" General Plugins
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'
Plug 'scrooloose/nerdtree' 
    \| Plug 'Xuyuanp/nerdtree-git-plugin'
    \| Plug 'ivalkeen/nerdtree-execute'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-fugitive'

" Webdev plugins
Plug 'othree/html5.vim'
Plug 'tpope/vim-surround'
Plug 'cakebaker/scss-syntax.vim'

" Other filetype specific
Plug 'lervag/vimtex'
Plug 'keith/tmux.vim'
Plug 'xu-cheng/brew.vim'

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

