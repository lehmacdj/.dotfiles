local lsp = require('my.lsp')

-- vim.lsp.log.set_level(vim.log.levels.INFO)

vim.lsp.config('*', {
  cmd_env = {
    -- HLS needs this env var set to not fail with inline-c. See these issues:
    -- - https://github.com/fpco/inline-c/pull/128
    -- - https://github.com/haskell/haskell-language-server/issues/3742
    __GHCIDE__ = 1
  },
  on_attach = lsp.on_attach,
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  flags = {
    debounce_text_changes = 150,
  },
})

lsp.enable('kotlin_language_server', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
})

lsp.enable('sourcekit', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
  cmd = { vim.trim(vim.fn.system('xcrun --find sourcekit-lsp')) },
})

lsp.enable('purescriptls')

lsp.enable('wiki_language_server')

lsp.enable('hls', {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = false
      }
    }
  },
  filetypes = {'haskell', 'lhaskell', 'cabal'},
  settings = {
    haskell = {
      formattingProvider = 'ormolu',
    },
  },
})

lsp.enable('lua_ls', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
  root_markers = {'selene.toml'},
})
require('lazydev').setup {
  -- this essentially configures the lua_ls equivalently to setting
  -- settings.Lua.workspace.library.path, but works with lazydev.nvim
  library = {
    path = os.getenv('DOTFILES') .. '/hammerspoon/Spoons/EmmyLua.spoon/annotations'
  },
}

-- toml, brew install taplo
lsp.enable('taplo', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
})
