" setup command to make stuff in my#plugins#defer# easier to use
" gets the source location where Defer was called and passes it to the
" underlying function for better diagnostics
command -nargs=+ Defer try | throw 'sourceloc' | catch | call my#plugins#defer#Defer(v:throwpoint, <args>) | endtry
" Delete the :Defer command we just defined when we run the deferred things
Defer {-> execute('delcommand Defer')}

call plug#begin($VIMHOME.'/plugged')

" general purpose vanilla-like behavior
Plug 'tpope/vim-unimpaired' " many useful shortcuts
Plug 'tpope/vim-abolish' " find replace with variants + snake/camel/kebab case changing
Plug 'tpope/vim-repeat' " '.' repeat for custom plugin actions
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-sleuth' " indent / shift-width config
Plug 'tpope/vim-surround' " actions to work on surrounding stuff
Plug 'wellle/targets.vim' " more text objects
Plug 'tommcdo/vim-exchange' " swap text between different locations
Plug 'tpope/vim-commentary' " comment / uncomment text
Plug 'junegunn/vim-easy-align'
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)
Plug 'tpope/vim-eunuch' " unix utilities
Plug 'lambdalisue/suda.vim'
let g:suda_smart_edit = 1

" ui / colorschemes
Plug 'overcache/NeoSolarized'
if has('nvim')
  Plug 'nvim-lualine/lualine.nvim'
  Defer 'require"lualine".setup()'
  Plug 'nvim-tree/nvim-web-devicons'
  Defer 'require"nvim-web-devicons".setup{ default = true }'
endif

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'knsh14/vim-github-link'
" gs is pretty much useless and nicely can mean `git stage`
nnoremap gs :GitGutterStageHunk<CR>
xnoremap gs :GitGutterStageHunk<CR>
" if you squint, gb is like gp for `git preview` but the p is upside down
nnoremap gb :GitGutterPreviewHunk<CR>

" ide plugins
if has('nvim')
  Plug 'github/copilot.vim'
  inoremap <C-.> <Plug>(copilot-suggest)
  inoremap <M-.> <Esc>:Copilot panel<CR>
  let g:copilot_filetypes = { 'markdown': v:false, }

  " nvim specific utils
  Plug 'nvim-lua/plenary.nvim'

  " treesitter
  Plug 'nvim-treesitter/nvim-treesitter'
  let s:treesitter_setup =<< trim EOF
    require'nvim-treesitter.configs'.setup {
      ensure_installed = {'bash', 'haskell', 'java', 'json', 'kotlin', 'lua', 'python', 'rust', 'swift', 'yaml'},
      highlight = {
        enable = true,
        disable = {'haskell'}, -- language names to disable highlighting for
        additional_vim_regex_highlighting = { 'markdown' },
      },
      indent = { enable = true },
    }
  EOF
  Defer s:treesitter_setup

  " pickers / nvim specific ui
  Plug 'stevearc/dressing.nvim'
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
  Defer 'require("my.telescope")'
  nnoremap <Leader>o :Telescope find_files<CR>
  nnoremap <Leader>/ :Telescope live_grep<CR>
  nnoremap <Leader>b :Telescope buffers<CR>
  nnoremap <Leader>] :Telescope grep_string<CR>
  " backup binding for lsp references (overriden in lua/my/lsp.lua)
  nnoremap g] :Telescope grep_string<CR>
  " finder resume
  nnoremap <Leader>fr :Telescope resume<CR>

  " lsp
  Plug 'neovim/nvim-lspconfig'
  Plug 'folke/lsp-colors.nvim'
  let s:lsp_setup =<< trim EOF
  require('my.lsp').define_custom_lsps()
  require('my.lsp').setup_lsps()
  EOF
  Defer s:lsp_setup

  Plug 'nvimtools/none-ls.nvim'
    \| Plug 'gbprod/none-ls-shellcheck.nvim'
  Defer 'require"my.null-ls".setup()'

  " completion
  Plug 'hrsh7th/nvim-cmp'
    \| Plug 'hrsh7th/cmp-nvim-lsp'
    \| Plug 'hrsh7th/cmp-buffer'
    \| Plug 'hrsh7th/cmp-path'
    \| Plug 'hrsh7th/cmp-cmdline'
    \| Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
    \| Plug 'jc-doyle/cmp-pandoc-references'
  Defer 'require"my.cmp".setup()'

  " Snippets
  Plug 'L3MON4D3/LuaSnip'
    \| Plug 'saadparwaiz1/cmp_luasnip'
    \| Plug 'rafamadriz/friendly-snippets'
  let s:luasnip_setup =<< trim EOF
  require('luasnip').config.set_config {
    enable_autosnippets = true,
  }
  require('luasnip.loaders.from_vscode').lazy_load()
  require('my.luasnippets').load()
  EOF
  Defer s:luasnip_setup
else
  " fzf bindings for finders is my fallback for Telescope
  nnoremap <Leader>o :FZF<CR>
  nnoremap <Leader>/ :Rg<CR>
  nnoremap <Leader>b :Buffers<CR>
endif

" language specific plugins
Plug 'neovimhaskell/haskell-vim'
" haskell block formatting: additional config in haskell after/ftplugin file
Plug 'sdiehl/vim-ormolu'
Plug 'udalov/kotlin-vim'
Plug 'tvaintrob/bicep.vim'
Plug 'vito-c/jq.vim'
Plug 'google/vim-jsonnet'
Plug 'tpope/vim-scriptease' " vimscript
Plug 'lervag/vimtex' | let g:tex_flavor = 'latex'
Plug 'xu-cheng/brew.vim' " Brewfile
Plug 'LnL7/vim-nix'
Plug 'idris-hackers/idris-vim'
Plug 'kana/vim-textobj-user'
  \ | Plug 'neovimhaskell/nvim-hs.vim'
  \ | Plug 'liuchengxu/vim-which-key'
  \ | Plug 'isovector/cornelis', { 'do': 'stack build' }
Plug 'purescript-contrib/purescript-vim'
Plug 'rust-lang/rust.vim'
" the fenced markdown languages need to be defined here, because otherwise they
" aren't set early enough for them to take effect
Plug 'tpope/vim-markdown'
let g:markdown_fenced_languages = [
  \ 'bash=sh',
  \ 'haskell',
  \ 'java',
  \ 'javascript',
  \ 'json',
  \ 'kotlin',
  \ 'python',
  \ 'rust',
  \ 'sql',
  \ 'swift',
  \ 'vim',
  \ 'xml',
\ ]
if has('nvim')
  " Plug 'OXY2DEV/markview.nvim'
  " see my/markview.lua for discussion on why I currently have this disabled
  " Defer 'require"my.markview".setup()'
  Plug 'wojciech-kulik/xcodebuild.nvim'
    \ | Plug 'MunifTanjim/nui.nvim'
  Defer 'require"xcodebuild".setup { xcodebuild_offline = { enabled = true } }'
end
Plug 'lehmacdj/neuron.vim', { 'branch': 'patched-old-neuron' } " zettelkasten support

call plug#end()
call my#plugins#defer#RunDeferred()

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
