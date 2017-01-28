call plug#begin($VIMHOME."/plugged")

" motion + text objects
Plug 'wellle/targets.vim'
Plug 'justinmk/vim-sneak'

" normal mode mappings
Plug 'tpope/vim-surround'
Plug 'tommcdo/vim-exchange'
Plug 'tpope/vim-commentary'
Plug 'junegunn/vim-easy-align'

" completion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
    \| Plug 'eagletmt/neco-ghc'
    \| Plug 'racer-rust/vim-racer'

" utility
Plug 'tpope/vim-repeat'

" unix
Plug 'tpope/vim-eunuch'

" fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
    \| Plug 'junegunn/fzf.vim'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" syntax checking
Plug 'benekastah/neomake'

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

" haskell
Plug 'parsonsmatt/intero-neovim'
Plug 'neovimhaskell/haskell-vim'

" rust
Plug 'rust-lang/rust.vim'

"swift
Plug 'keith/swift.vim'

" ui
Plug 'vim-airline/vim-airline'
    \| Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
Plug 'altercation/vim-colors-solarized'

call plug#end()
