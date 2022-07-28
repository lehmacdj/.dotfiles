" setup command to make stuff in config#plugins#defer# easier to use
command -nargs=+ Defer call config#plugins#defer#Defer(<args>)
" Delete the :Defer command we just defined when we run the deferred things
Defer {-> execute('delcommand Defer')}

call plug#begin($VIMHOME.'/plugged')

" general purpose vanilla-like behavior
Plug 'tpope/vim-unimpaired' " many useful shortcuts
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
    Plug 'github/copilot.vim'

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
            ['<C-q>'] = function(prompt_bufnr)
              require('telescope.actions').smart_send_to_qflist(prompt_bufnr)
              vim.cmd('cc 1')
            end,
            ['<M-q>'] = false,
            ['<C-j>'] = 'move_selection_next',
            ['<C-n>'] = 'move_selection_next',
            ['<C-k>'] = 'move_selection_previous',
            ['<C-p>'] = 'move_selection_previous'
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

    " lsp
    Plug 'neovim/nvim-lspconfig'
    Plug 'folke/lsp-colors.nvim'
    let s:lsp_setup =<< trim EOF
    local lsp = require('lspconfig')

    local capabilities = require('cmp_nvim_lsp')
      .update_capabilities(vim.lsp.protocol.make_client_capabilities())

    -- configure my custom lsp for markdown (eventually when this is mature,
    -- I think I should be able to get this into the proper repo)
    local configs = require 'lspconfig.configs'
    configs.wiki_language_server = {
      default_config = {
        cmd = {'wiki-language-server'};
        filetypes = {'markdown'};
        root_dir = function(fname)
          return lsp.util.root_pattern('.git', 'test*')(fname);
        end;
        settings = {};
      };
    }

    local server_opts = {
      hls = {
        no_formatting = true,
      },
      wiki_language_server = {},
      purescriptls = {},
    }

    -- Use a loop to conveniently call 'setup' on multiple servers and
    -- map buffer local keybindings when the language server attaches
    for name, opts in pairs(server_opts) do
      lsp[name].setup {
        on_attach = require('config').on_attach_with(opts),
        flags = {
          debounce_text_changes = 150,
        },
        capabilities = capabilities,
      }
    end
    EOF
    Defer s:lsp_setup

    Plug 'jose-elias-alvarez/null-ls.nvim'
    let s:null_ls_setup =<< trim EOF
    local null_ls = require('null-ls')
    local formatting = null_ls.builtins.formatting
    local diagnostics = null_ls.builtins.diagnostics
    local code_actions = null_ls.builtins.code_actions
    null_ls.setup {
      on_attach = require('config').on_attach,
      -- diagnostics_format = '#{c}: #{m}",
      sources = {
        formatting.fourmolu.with {
          command = 'ormolu',
          extra_args = {'-o', '-XTypeApplications', '-o', '-XImportQualifiedPost'},
        },
        formatting.cabal_fmt,
        -- prettier is absurdly slow
        -- installation: npm install -g @fsouza/prettierd
        formatting.prettierd.with {
          filetypes = {
            'javascript', 'javascriptreact',
            'typescript', 'typescriptreact',
            'vue',
            'css', 'scss', 'less',
            'graphql',
            'handlebars',
          },
        },
        diagnostics.selene,
        diagnostics.shellcheck.with {
          diagnostics_format = 'SC#{c}: #{m}',
        },
        code_actions.shellcheck,
        diagnostics.vint,
      },
    }
    EOF
    Defer s:null_ls_setup

    " completion
    Plug 'hrsh7th/nvim-cmp'
        \| Plug 'hrsh7th/cmp-nvim-lsp'
        \| Plug 'hrsh7th/cmp-buffer'
        \| Plug 'hrsh7th/cmp-path'
        \| Plug 'hrsh7th/cmp-cmdline'
        \| Plug 'L3MON4D3/LuaSnip'
            \| Plug 'saadparwaiz1/cmp_luasnip'
            \| Plug 'rafamadriz/friendly-snippets'
    let s:cmp_setup =<< trim EOF
    require('luasnip.loaders.from_vscode').load()
    local cmp = require('cmp')
    local Behavior = require('cmp.types').cmp.SelectBehavior
    cmp.setup {
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body)
        end,
      },
      enabled = function()
        -- disable completion in comments
        local context = require 'cmp.config.context'
        local ok, ts_in_comment = pcall(context.in_treesitter_capture, 'comment')
        return not (ok and ts_in_comment)
          and not context.in_syntax_group('Comment')
          and vim.opt.filetype:get() ~= 'TelescopePrompt'
        end,
      mapping = {
        ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
        ['<C-y>'] = cmp.config.disable,
        ['<C-e>'] = cmp.mapping({
          i = cmp.mapping.abort(),
          c = cmp.mapping.close(),
        }),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
        ['<Down>'] = {
          i = cmp.mapping.select_next_item({ behavior = Behavior.Select }),
        },
        ['<Up>'] = {
          i = cmp.mapping.select_prev_item({ behavior = Behavior.Select }),
        },
        ['<C-n>'] = {
          i = cmp.mapping.select_next_item({ behavior = Behavior.Insert }),
        },
        ['<C-p>'] = {
          i = cmp.mapping.select_prev_item({ behavior = Behavior.Insert }),
        },
      },
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        {
          name = 'buffer',
          option = {
            get_bufnrs = function()
              return vim.api.nvim_list_bufs()
            end,
          },
        },
        { name = 'luasnip' },
        { name = 'path' },
      })
    }
    EOF
    Defer s:cmp_setup
else
    " fzf bindings for finders if applicable
    nnoremap <Leader>o :FZF<CR>
    nnoremap <Leader>/ :Rg<CR>
    nnoremap <Leader>b :Buffers<CR>
endif

" language specific plugins
Plug 'neovimhaskell/haskell-vim'
" haskell block formatting: additional config in haskell after/ftplugin file
Plug 'sdiehl/vim-ormolu'
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
Plug 'keith/swift.vim'
" the fenced markdown languages need to be defined here, because otherwise they
" aren't set early enough for them to take effect
Plug 'tpope/vim-markdown'
    \| let g:markdown_fenced_languages = ['haskell', 'rust', 'bash=sh', 'python', 'sql', 'json', 'javascript']
Plug 'lehmacdj/neuron.vim', { 'branch': 'patched-old-neuron' } " zettelkasten support
Plug 'Simspace/avaleryar', { 'rtp': 'tools/vim' }

call plug#end()
call config#plugins#defer#RunDeferred()

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
