" this stuff defines mechanisms for writing setup code for a plugin next to
" where the plugin is defined but then only running it after the plugins have
" loaded successfully. This machinery is only intended to be used exactly once
" just after calling plug#end.
let s:deferred = []

function! s:Defer(arg)
    let l:t = type(a:arg)
    if l:t == 1 || l:t == 2
        " strings and funcrefs can be immediately appended to s:deferred: we
        " know how to run them (either interpret as lua or execute funref)
        let s:deferred += [a:arg]
    elseif l:t == 3
        " arrays are produced by let-heredoc syntax, convert them to a string
        " first so they will be interpreted by lua when run
        let s:deferred += [join(a:arg, "\n") . "\n"]
    else
        call config#err(printf('Invalid argument type for Defer: %s', l:t))
    endif
endfunction

function! s:RunDeferred()
    " we need to use s:action because local-variables can't store Funcrefs
    for s:action in s:deferred
        if type(s:action) == 1
            " s:action is a snippet of lua code; we call loadstring within
            " luaeval to allow s:action to be a string with potentially
            " several commands in it
            call luaeval('loadstring(_A)()', s:action)
        elseif type(s:action) == 2
            " s:action is a function reference / anonymous function
            call s:action()
        else
            throw printf('invalid type: %d', type(l:action))
        endif
    endfor
    unlet s:deferred
endfunction

command -nargs=+ Defer call <SID>Defer(<args>)
" Delete the :Defer command when we run the deferred things
call s:Defer({-> execute('delcommand Defer')})

augroup PluginAutoInstall
  autocmd!
  " Run PlugInstall if there are missing plugins automatically, profiling
  " shows this takes about 0.0003 seconds which is probably a reasonable cost
  " for the convenience. Performance probably slows more when there are more
  " plugins though so its a thing to watch out for. @performance
  autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
    \| PlugInstall --sync | source $MYVIMRC
  \| endif
augroup END

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
if has('nvim')
    Plug 'kyazdani42/nvim-web-devicons'
    Defer 'require"nvim-web-devicons".setup{ default = true }'
endif
" we always use vim-devicons because some plugins don't work with
" nvim-web-devicons (notably airline)
Plug 'ryanoasis/vim-devicons'
Plug 'frankier/neovim-colors-solarized-truecolor-only'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'knsh14/vim-github-link'

" we always need fzf even if using telescope.nvim because neuron.vim depends
" on it currently
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
    \| Plug 'junegunn/fzf.vim'

" ide plugins
if has('nvim')
    " nvim specific utils
    Plug 'nvim-lua/plenary.nvim'

    " pickers / nvim specific ui
    Plug 'nvim-telescope/telescope.nvim'
    Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
    let s:telescope_setup =<< trim EOF
    require('telescope').setup{
      defaults = {
        mappings = {
          i = {
            ["<C-q>"] = function(prompt_bufnr)
              require('telescope.actions').smart_send_to_qflist(prompt_bufnr)
              vim.cmd("cc 1")
            end,
            ["<M-q>"] = false,
            ["<C-n>"] = "cycle_history_next",
            ["<C-p>"] = "cycle_history_prev",
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous"
          }
        }
      }
    }
    require('telescope').load_extension('fzf')
    EOF
    Defer s:telescope_setup
    nnoremap <Leader>o :Telescope find_files<CR>
    nnoremap <Leader>/ :Telescope live_grep<CR>
    nnoremap <Leader>b :Telescope buffers<CR>
    nnoremap <Leader>] :Telescope grep_string<CR>
    nnoremap <Leader>fr :Telescope resume<CR>

    " " lsp
    " Plug 'neovim/nvim-lspconfig' " TODO
    " Plug 'folke/lsp-colors.nvim' " TODO
    " Plug 'jose-elias-alvarez/null-ls.nvim' " TODO

    " " completion
    " Plug 'hrsh7th/cmp-nvim-lsp'
    " Plug 'hrsh7th/cmp-buffer'
    " Plug 'hrsh7th/cmp-path'
    " Plug 'hrsh7th/cmp-cmdline'
    " Plug 'hrsh7th/nvim-cmp' " TODO
else
    " fzf bindings for finders if applicable
    nnoremap <Leader>o :FZF<CR>
    nnoremap <Leader>/ :Rg<CR>
    nnoremap <Leader>b :Buffers<CR>
endif

" completion / lsp
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install'}
source $VIMHOME/coc-config.vim
" Edit Coc config file
" mnemonic is language server because 'c' is already taken by 'config'
nnoremap <Leader>el :split $VIMHOME/coc-config.vim<CR>

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
    \| let g:markdown_fenced_languages = ['haskell', 'rust', 'bash=sh', 'python', 'sql']
Plug 'lehmacdj/neuron.vim', { 'branch': 'patched-old-neuron' } " zettelkasten support

call plug#end()

call s:RunDeferred()
