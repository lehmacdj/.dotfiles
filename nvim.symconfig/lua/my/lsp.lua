local mod = {}

-- Configuration for the language servers we want to use. This is called in
-- `mod.setup_lsps`.
--
-- the keys are the names of the language servers, we support several options:
-- 1. no_formatting: boolean, if true, we disable formatting for this server
-- 2. setup: table, additional setup for the server passed to the setup function
-- 3. modify_capabilities: function, a function that takes the capabilities and
--   returns the modified capabilities, useful for disabling capabilities that
--   make certain servers misbehave (e.g. see hls)
local server_opts = {
  hls = {
    modify_capabilities = function(capabilities)
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
      return capabilities
    end,
    setup = {
      -- HLS 1.9.0.0+ recommended that I explicitly enable cabal files
      -- this will probably be unnecessary with some future version of nvim's
      -- default lsp configs
      filetypes = {'haskell', 'lhaskell', 'cabal'},
      haskell = {
        formattingProvider = 'ormolu',
      },
    },
  },
  wiki_language_server = {},
  purescriptls = {},
  omnisharp = {
    setup = {
      cmd = {'dotnet', '/Users/devin/opt/omnisharp/OmniSharp.dll'},
      enable_rosalyn_analyzers = true,
      organize_imports_on_format = true,
      enable_import_completion = true,
    },
  },
  kotlin_language_server = {
    no_formatting = true, -- horrendously slow / broken
  },
  sourcekit =  {
    no_formatting = true,
    setup = {
      cmd = { vim.trim(vim.fn.system('xcrun --find sourcekit-lsp')) },
    },
  },
}

-- To be called from plugins.vim to setup all the language servers defined in
-- the server_opts table
mod.setup_lsps = function()
  -- vim.lsp.log.set_level(vim.log.levels.INFO)
  local default_capabilities = vim.tbl_deep_extend(
    'keep',
    vim.lsp.protocol.make_client_capabilities(),
    require('cmp_nvim_lsp').default_capabilities()
  )

  -- Use a loop to conveniently call 'setup' on multiple servers and
  -- map buffer local keybindings when the language server attaches
  for name, opts in pairs(server_opts) do
    local modify_capabilities = opts.modify_capabilities or function(c) return c end
    local setup_opts = {
      on_attach = mod.on_attach_with(opts),
      flags = {
        debounce_text_changes = 150,
      },
      capabilities = modify_capabilities(default_capabilities),
    }
    local setup_opt_overrides = opts.setup or {}
    for k,v in pairs(setup_opt_overrides) do setup_opts[k] = v end
    require('lspconfig')[name].setup(setup_opts)
  end
end

mod.guarded_autoformat = function(...)
  if vim.g.do_autoformat then
    vim.lsp.buf.format(...)
  end
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer.
-- defined globally so that we can use this for null_ls as well
mod.on_attach_with = function(opts) return function(client, bufnr)
  if opts.no_formatting then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  local function buf_set_keymap(mode, keys, map)
    vim.api.nvim_buf_set_keymap(bufnr, mode, keys, map, {noremap=true, silent=true})
  end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- always mappings (these make sense regardless of the capabilities of
  -- the server
  buf_set_keymap('n', '<Leader>lr', '<cmd>LspRestart<CR>')

  -- always attach diagnostics mappings because it doesn't look like there
  -- is a capability for it + it doesn't hurt because these mappings don't
  -- overwrite anything (important at least)
  -- [d / ]d are the default mappings, but I prefer using my index finger
  buf_set_keymap('n', '[g', '<cmd>lua vim.diagnostic.goto_prev{focus = false}<CR>')
  buf_set_keymap('n', ']g', '<cmd>lua vim.diagnostic.goto_next{focus = false}<CR>')
  buf_set_keymap('n', '<Leader>q', '<cmd>lua vim.diagnostic.setqflist{open = false}<CR>:cc 1<CR>')
  vim.cmd [[
    augroup LspDiagnostics
      autocmd! * <buffer>
      autocmd CursorHold * silent! lua vim.diagnostic.open_float {scope = "cursor", focus = false}
    augroup END
  ]]

  if client:supports_method("textDocument/hover") then
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  end
  if client:supports_method("textDocument/declaration") then
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  end
  if client:supports_method("textDocument/definition") then
    buf_set_keymap('n', '<C-]>', '<cmd>lua vim.lsp.buf.definition()<CR>')
  end
  if client:supports_method("textDocument/implementation") then
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  end
  if client:supports_method("textDocument/typeDefinition") then
    buf_set_keymap('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  end
  if client:supports_method("textDocument/references") then
    -- this overwrites the grep_string mapping I have because in practice I
    -- mostly use grep_string like "find references"
    buf_set_keymap('n', 'g]', '<cmd>Telescope lsp_references<CR>')
  end
  if client:supports_method("textDocument/rename") then
    buf_set_keymap('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
  end
  if client:supports_method("textDocument/codeAction") then
    buf_set_keymap('n', '<Leader>al', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  end
  if not opts.no_formatting and client:supports_method("textDocument/formatting") then
    buf_set_keymap('n', '<space>=', [[<cmd>lua require('my.lsp').guarded_autoformat()<CR>]])
    vim.cmd [[
      augroup LspFormatting
        autocmd! * <buffer>
        autocmd BufWritePre <buffer> lua require('my.lsp').guarded_autoformat()
      augroup END
    ]]
  end
end end

mod.on_attach = mod.on_attach_with {}

mod.define_custom_lsps = function()
  local lsp = require('lspconfig')
  local configs = require('lspconfig.configs')
  -- configure my custom lsp for markdown (eventually when this is mature,
  -- I think I should be able to get this into the proper repo)
  -- the nvim-lspconfig does this with magic and overwriting the lsp again
  -- breaks the magic so we need to be careful to only write it once
  if configs.wiki_language_server == nil then
    configs.wiki_language_server = {
      default_config = {
        cmd = {'wiki-language-server'};
        filetypes = {'markdown'};
        root_dir = function(fname)
          return lsp.util.root_pattern('.git')(fname);
        end;
        settings = {};
      };
    }
  end
end

return mod
