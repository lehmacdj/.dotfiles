call plug#begin($VIMHOME."/plugged")

" general purpose vanilla-like behavior
Plug 'tpope/vim-unimpaired' " many useful shortcuts
Plug 'tpope/vim-repeat' " '.' repeat for custom plugin actions
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-sleuth' " indent / shift-width config
Plug 'tpope/vim-surround' " actions to work on surrounding stuff
Plug 'wellle/targets.vim' " more text objects
Plug 'tommcdo/vim-exchange' " swap text between different locations
Plug 'tpope/vim-commentary' " comment / uncomment text
Plug 'junegunn/vim-easy-align' " align stuff
Plug 'tpope/vim-eunuch' " unix utilities

" ui / colorschemes
Plug 'vim-airline/vim-airline'
    \| Plug 'vim-airline/vim-airline-themes'
" the hunk / branchname display takes up too much space and obscures the
" filename often; this makes it take less space / not appear a lot of the time
let g:airline_section_b = '%{airline#util#wrap(airline#extensions#hunks#get_hunks(),100)}%{airline#util#wrap(airline#extensions#branch#get_head(),200)}'
Plug 'ryanoasis/vim-devicons'
Plug 'frankier/neovim-colors-solarized-truecolor-only'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" completion / lsp
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install'}
source $VIMHOME/coc-config.vim
" Edit Coc config file
" mnemonic is language server because 'c' is already taken by 'config'
nnoremap <Leader>el :split $VIMHOME/coc-config.vim<CR>

" fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
  \| Plug 'junegunn/fzf.vim'

" syntax checking
Plug 'dense-analysis/ale'
" don't need ale linters for haskell because have HLS
let g:ale_linters = { 'haskell': [] }
let g:ale_fixers = { 'haskell': [] }

" language specific plugins
Plug 'neovimhaskell/haskell-vim'
Plug 'sdiehl/vim-ormolu' " haskell autoformatting
Plug 'sdiehl/vim-cabalfmt' " cabal file autoformatting
Plug 'google/vim-jsonnet'
Plug 'tpope/vim-scriptease' " vimscript
Plug 'lervag/vimtex' | let g:tex_flavor = 'latex'
Plug 'xu-cheng/brew.vim' " Brewfile
Plug 'LnL7/vim-nix'
Plug 'idris-hackers/idris-vim'
Plug 'purescript-contrib/purescript-vim'
Plug 'rust-lang/rust.vim'
Plug 'keith/swift.vim'
Plug 'tpope/vim-markdown'
  \| let g:markdown_fenced_languages = ['haskell', 'rust', 'bash=sh', 'python']
Plug 'lehmacdj/neuron.vim', { 'branch': 'patched-old-neuron' } " zettelkasten support

call plug#end()
