" declaration of plugins
call plug#begin("$VIMHOME/plugged")

" syntax checking
Plug 'benekastah/neomake'

" surrounding stuff
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'

" unix
Plug 'tpope/vim-eunuch'

" statusline
Plug 'vim-airline/vim-airline'
    \| Plug 'vim-airline/vim-airline-themes'
    \| Plug 'edkolev/tmuxline.vim'

" filebrowser
Plug 'scrooloose/nerdtree'
    \| Plug 'Xuyuanp/nerdtree-git-plugin'
    \| Plug 'ivalkeen/nerdtree-execute'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" beautify some stuff with icons
Plug 'ryanoasis/vim-devicons'

" solarized theme
Plug 'altercation/vim-colors-solarized'

" latex
Plug 'lervag/vimtex'

" tmux syntax
Plug 'keith/tmux.vim'

" homebrew syntax
Plug 'xu-cheng/brew.vim'

" vim stuff
Plug 'tpope/vim-scriptease'

" markdown
Plug 'tpope/vim-markdown'

" webdev
Plug 'othree/html5.vim'
Plug 'cakebaker/scss-syntax.vim'

call plug#end()

" configuration of plugins

" map something to NERDTreeToggle
nnoremap <silent> <Leader>n :NERDTreeToggle<CR>

" use solarized theme
set background=dark
colorscheme solarized
call togglebg#map("<F3>")

" enable powerline font in airline
let g:airline_powerline_fonts = 1
