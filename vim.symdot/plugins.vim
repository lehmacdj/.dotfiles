call plug#begin('~/.vim/plugged')

" Motion Plugins
Plug 'wellle/targets.vim'
Plug 'tpope/vim-surround'
Plug 'justinmk/vim-sneak'
Plug 'tpope/vim-repeat'

" Convenience Plugins
Plug 'tpope/vim-eunuch'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-fugitive'

" UI Plugins
Plug 'scrooloose/nerdtree'
    \| Plug 'Xuyuanp/nerdtree-git-plugin'
    \| Plug 'ivalkeen/nerdtree-execute'
Plug 'vim-airline/vim-airline'
    \| Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'
Plug 'scrooloose/syntastic'
Plug 'airblade/vim-gitgutter'

" vim-vim-plugins
Plug 'tpope/vim-scriptease'

" perl-plugins
Plug 'vim-perl/vim-perl'

" R plugins
Plug 'vim-scripts/csv.vim'

" Webdev plugins
Plug 'othree/html5.vim'
Plug 'tpope/vim-markdown'
Plug 'cakebaker/scss-syntax.vim'

" Other filetype specific
Plug 'lervag/vimtex'
Plug 'keith/tmux.vim'
Plug 'xu-cheng/brew.vim'

" Solarized
Plug 'altercation/vim-colors-solarized'

" Devicons
Plug 'ryanoasis/vim-devicons'
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
nnoremap <Leader>n :NERDTreeToggle<cr>

" Solarized
syntax enable
set background=dark
colorscheme solarized
call togglebg#map("<F3>")

" vim-devicons
let g:airline_powerline_fonts = 1

" ocaml configuration dependent on opam
let g:opamshare = substitute(system('opam config var share'),'\n$','','''')
if v:shell_error == 0
    " merlin
    execute "set rtp+=" . g:opamshare . "/merlin/vim"
    execute "helptags " . g:opamshare . "/merlin/vim/doc"
    let g:syntastic_ocaml_checkers = ['merlin']

    " ocp-indent
    execute "set rtp+=" . g:opamshare . "/ocp-indent/vim"
endif
