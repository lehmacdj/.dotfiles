local mod = {}

mod.guarded_autoformat = function(...)
  if vim.g.do_autoformat then
    vim.lsp.buf.format(...)
  end
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer.
-- defined globally so that we can use this for null_ls as well
mod.on_attach_opts = function(opts) return function(client, bufnr)
  if opts.no_formatting then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  local function buf_set_keymap(mode, keys, map)
    vim.api.nvim_buf_set_keymap(bufnr, mode, keys, map, {noremap=true, silent=true})
  end

  -- always mappings (these make sense regardless of the capabilities of
  -- the server
  buf_set_keymap('n', '<Leader>lr', '<cmd>LspRestart<CR>')

  -- always attach diagnostics mappings because it doesn't look like there
  -- is a capability for it + it doesn't hurt because these mappings don't
  -- overwrite anything (important at least)
  -- [d / ]d are the default mappings, but I prefer using my index finger
  buf_set_keymap('n', '[g', '<cmd>lua vim.diagnostic.jump{count=-1}<CR>')
  buf_set_keymap('n', ']g', '<cmd>lua vim.diagnostic.jump{count=1}<CR>')
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

mod.on_attach = mod.on_attach_opts {}

-- Helper to configure and enable a server
mod.enable = function(server, config)
  if config then
    vim.lsp.config(server, config)
  end
  vim.lsp.enable(server)
end

return mod
