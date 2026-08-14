local lsp = require('my.lsp')

-- vim.lsp.log.set_level(vim.log.levels.INFO)

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, 'blink.cmp')
if ok then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

vim.lsp.config('*', {
  cmd_env = {
    -- HLS needs this env var set to not fail with inline-c. See these issues:
    -- - https://github.com/fpco/inline-c/pull/128
    -- - https://github.com/haskell/haskell-language-server/issues/3742
    __GHCIDE__ = 1
  },
  on_attach = lsp.on_attach,
  capabilities = capabilities,
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

lsp.enable('wiki_language_server', {
  cmd = { 'wiki', 'language-server' },
  on_attach = function(client, bufnr)
    lsp.on_attach(client, bufnr)
    local function wiki_cmd(command, args)
      client:request(
        'workspace/executeCommand',
        {
          command = command,
          arguments = args or { vim.uri_from_bufnr(bufnr) },
        },
        nil,
        bufnr
      )
    end
    local function wiki_map(lhs, command)
      vim.keymap.set('n', lhs, function()
        wiki_cmd(command)
      end, { buffer = bufnr, noremap = true, silent = true })
    end
    -- day-wise navigation; missing notes are created on the fly
    wiki_map('[d', 'wiki.prevDay')
    wiki_map(']d', 'wiki.nextDay')
    -- week-wise navigation, snapping to the configured start of week
    wiki_map('[w', 'wiki.prevWeek')
    wiki_map(']w', 'wiki.nextWeek')
    wiki_map('<LocalLeader>w', 'wiki.thisWeek')
    wiki_map('<LocalLeader>t', 'wiki.today')
    -- jump to a day described in natural language, e.g. "last friday"
    vim.keymap.set('n', '<LocalLeader>j', function()
      vim.ui.input({ prompt = 'Go to date: ' }, function(input)
        if input and vim.trim(input) ~= '' then
          wiki_cmd('wiki.jumpToDate', { input })
        end
      end)
    end, { buffer = bufnr, noremap = true, silent = true })
  end,
})

lsp.enable('hls', {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = false
      }
    }
  },
  filetypes = {'haskell', 'lhaskell', 'cabal'},
  -- HLS formatting version is old and can't use a version from the path
  -- without recompiling from source; instead use none-ls for Ormolu
  on_attach = lsp.on_attach_opts { no_formatting = true },
})

lsp.enable('lua_ls', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
  root_markers = {'selene.toml'},
})
require('lazydev').setup {}

-- toml, brew install taplo
lsp.enable('taplo', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
})

-- go install github.com/sqls-server/sqls@latest
-- need to setup connection strings in ~/.config/sqls/config.yml
lsp.enable('sqls')
