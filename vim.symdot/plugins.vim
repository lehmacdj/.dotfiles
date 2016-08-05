" Use matchit builtin plugin
runtime 'macros/matchit.vim'

call plug#begin('~/.vim/plugged')

" Motion Plugins
Plug 'wellle/targets.vim'
Plug 'tpope/vim-surround'
Plug 'justinmk/vim-sneak'
Plug 'tpope/vim-repeat'
Plug 'tommcdo/vim-exchange'

" Convenience Plugins
Plug 'tpope/vim-eunuch'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'

" UI Plugins
Plug 'vim-airline/vim-airline'
    \| Plug 'vim-airline/vim-airline-themes'
Plug 'scrooloose/nerdtree'
    \| Plug 'Xuyuanp/nerdtree-git-plugin'
    \| Plug 'ivalkeen/nerdtree-execute'
Plug 'edkolev/tmuxline.vim'
Plug 'scrooloose/syntastic'
Plug 'airblade/vim-gitgutter'

" vim-vim-plugins
Plug 'tpope/vim-scriptease'

" swift
Plug 'keith/swift.vim'

" perl-plugins
Plug 'vim-perl/vim-perl'

" R plugins
Plug 'vim-scripts/csv.vim'

" Webdev plugins
Plug 'othree/html5.vim'
Plug 'tpope/vim-markdown'
Plug 'cakebaker/scss-syntax.vim'
Plug 'lilydjwg/colorizer'

" Other filetype specific
Plug 'lervag/vimtex'
Plug 'keith/tmux.vim'
Plug 'xu-cheng/brew.vim'

" Solarized
Plug 'altercation/vim-colors-solarized'

" Devicons
Plug 'ryanoasis/vim-devicons'
call plug#end()

" Solarized
colorscheme solarized
call togglebg#map("<F3>")

" vim-devicons
let g:airline_powerline_fonts = 1

" Externally managed plugins
if executable('opam')
    let g:opamshare = substitute(system('opam config var share'), '\n$', '', '''')

    if executable('ocamlmerlin') && has('python')
        execute "set rtp+=".g:opamshare . "/merlin/vim"
        " To update the documentation
        " execute "helptags " . g:opamshare . "/merlin/vim/doc"
        let g:syntastic_ocaml_checkers=['merlin']
    endif

    if executable('ocp-indent')
        execute "set rtp+=" . g:opamshare . "/ocp-indent/vim"
    endif
endif
