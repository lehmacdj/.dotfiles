local mod = {}

-- autoformatting utilities
if vim.g.do_lsp_autoformat == nil then
  vim.g.do_lsp_autoformat = true
end
mod.guarded_autoformat = function(...)
  if vim.g.do_lsp_autoformat then
    vim.lsp.buf.format(...)
  end
end
-- looking for toggle autoformat? Either do:
-- vim.g.do_lsp_autoformat = not vim.g.do_lsp_autoformat
-- if feedback isn't important, or otherwise follow the guide of the yo= mapping
-- which first checks and alternately executes disable / enable to give better
-- feedback
mod.disable_autoformat = function()
  vim.g.do_lsp_autoformat = false
end
mod.enable_autoformat = function()
  vim.g.do_lsp_autoformat = true
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
  buf_set_keymap('n', '[g', '<cmd>lua vim.diagnostic.goto_prev{focus = false}<CR>')
  buf_set_keymap('n', ']g', '<cmd>lua vim.diagnostic.goto_next{focus = false}<CR>')
  buf_set_keymap('n', '<Leader>q', '<cmd>lua vim.diagnostic.setqflist()<CR>')
  vim.cmd [[
    augroup LspDiagnostics
      autocmd! * <buffer>
      autocmd CursorHold * silent! lua vim.diagnostic.open_float {scope = "cursor", focus = false}
    augroup END
  ]]

  if client.supports_method("textDocument/hover") then
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  end
  if client.supports_method("textDocument/declaration") then
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  end
  if client.supports_method("textDocument/definition") then
    buf_set_keymap('n', '<C-]>', '<cmd>lua vim.lsp.buf.definition()<CR>')
    buf_set_keymap('n', 'g]', '<cmd>Telescope lsp_definitions<CR>')
  end
  if client.supports_method("textDocument/implementation") then
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  end
  if client.supports_method("textDocument/typeDefinition") then
    buf_set_keymap('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  end
  if client.supports_method("textDocument/references") then
    buf_set_keymap('n', 'gr', '<cmd>Telescope lsp_references<CR>')
  end
  if client.supports_method("textDocument/rename") then
    buf_set_keymap('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
  end
  if client.supports_method("textDocument/codeAction") then
    buf_set_keymap('n', '<Leader>al', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  end
  if not opts.no_formatting and client.supports_method("textDocument/formatting") then
    buf_set_keymap('n', '<space>=', [[<cmd>lua require('config').guarded_autoformat()<CR>]])
    vim.cmd [[
      augroup LspFormatting
        autocmd! * <buffer>
        autocmd BufWritePre <buffer> lua require('config').guarded_autoformat()
      augroup END
    ]]
  end
end end

mod.on_attach = mod.on_attach_with {}

return mod
