call plug#begin($VIMHOME."/plugged")

" motion + text objects
Plug 'wellle/targets.vim'

" normal mode mappings
Plug 'tpope/vim-surround'
Plug 'tommcdo/vim-exchange'
Plug 'tpope/vim-commentary'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-unimpaired'

" completion
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install'}
source $VIMHOME/coc-config.vim
" Edit Coc config file
" mnemonic is language server because 'c' is already taken by 'config'
nnoremap <Leader>el :split $VIMHOME/coc-config.vim<CR>

" utility
Plug 'tpope/vim-repeat'
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-sleuth'

" unix
Plug 'tpope/vim-eunuch'

" fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
    \| Plug 'junegunn/fzf.vim'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" syntax checking
Plug 'dense-analysis/ale'
" don't need ale linters for haskell because have HLS
let g:ale_linters = { 'haskell': [] }
let g:ale_fixers = { 'haskell': [] }

" jsonnet
Plug 'google/vim-jsonnet'

" vim
Plug 'tpope/vim-scriptease'

" latex
Plug 'lervag/vimtex'
let g:tex_flavor = 'latex'

" tmux
Plug 'keith/tmux.vim'
Plug 'edkolev/tmuxline.vim'

" Brewfile
Plug 'xu-cheng/brew.vim'

" nix
Plug 'LnL7/vim-nix'

" idris
Plug 'idris-hackers/idris-vim'

" purescript
Plug 'purescript-contrib/purescript-vim'
Plug 'FrigoEU/psc-ide-vim'

" haskell
Plug 'neovimhaskell/haskell-vim'
" Plug 'parsonsmatt/intero-neovim'
Plug 'sdiehl/vim-ormolu'
Plug 'sdiehl/vim-cabalfmt'

" rust
Plug 'rust-lang/rust.vim'

"swift
Plug 'keith/swift.vim'

" ui
Plug 'vim-airline/vim-airline'
    \| Plug 'vim-airline/vim-airline-themes'
let g:airline_section_b = '%{airline#util#wrap(airline#extensions#hunks#get_hunks(),100)}%{airline#util#wrap(airline#extensions#branch#get_head(),200)}'

Plug 'ryanoasis/vim-devicons'
Plug 'frankier/neovim-colors-solarized-truecolor-only'
" Currently using this plugin because normal vim-colors-solarized doesn't
" support termguicolors
" Plug 'altercation/vim-colors-solarized'

" markdown / neuron zettelkasten / note-taking
Plug 'tpope/vim-markdown'
let g:markdown_fenced_languages = ['haskell', 'rust', 'bash=sh', 'python']
Plug 'lehmacdj/neuron.vim', { 'branch': 'patched-old-neuron' }

call plug#end()
