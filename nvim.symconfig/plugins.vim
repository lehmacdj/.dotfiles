call plug#begin($VIMHOME."/plugged")

" motion + text objects
Plug 'wellle/targets.vim'
Plug 'justinmk/vim-sneak'

" normal mode mappings
Plug 'tpope/vim-surround'
Plug 'tommcdo/vim-exchange'
Plug 'tpope/vim-commentary'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-unimpaired'

" completion
if has('nvim')
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
        \| Plug 'racer-rust/vim-racer'
        \| Plug 'Shougo/neoinclude.vim'
        \| Plug 'zchee/deoplete-jedi'
end

" utility
Plug 'tpope/vim-repeat'
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-sleuth'
Plug 'sheerun/vim-polyglot'

" unix
Plug 'tpope/vim-eunuch'

" fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
    \| Plug 'junegunn/fzf.vim'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" syntax checking
Plug 'neomake/neomake'

" jsonnet
Plug 'google/vim-jsonnet'

" vim
Plug 'tpope/vim-scriptease'

" latex
Plug 'lervag/vimtex'

" tmux
Plug 'keith/tmux.vim'
Plug 'edkolev/tmuxline.vim'

" Brewfile
Plug 'xu-cheng/brew.vim'

" markdown
Plug 'tpope/vim-markdown'

" idris
Plug 'idris-hackers/idris-vim'

" purescript
Plug 'purescript-contrib/purescript-vim'
Plug 'FrigoEU/psc-ide-vim'

" haskell
Plug 'neovimhaskell/haskell-vim'
Plug 'parsonsmatt/intero-neovim'

" rust
Plug 'rust-lang/rust.vim'

"swift
Plug 'keith/swift.vim'

" ui
Plug 'vim-airline/vim-airline'
    \| Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
Plug 'altercation/vim-colors-solarized'

" c#

call plug#end()

" opam plugins
if executable('opam')
    let g:opamshare = substitute(system('opam config var share'), '\n$', '', '''')

    if executable('ocamlmerlin') && has('python')
        execute "set rtp+=".g:opamshare . "/merlin/vim"
    endif

    if executable('ocp-indent')
        execute "set rtp+=" . g:opamshare . "/ocp-indent/vim"
    endif
endif
