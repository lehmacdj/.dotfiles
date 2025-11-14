local mod = {}

mod.guarded_autoformat = function(...)
  if vim.g.do_autoformat then
    vim.lsp.buf.format(...)
  end
end

-- This function is called when LSP servers attach to a buffer. It sets up
-- keymaps dependent on the capabilities of the server.
-- see also `:h lsp-defaults` for extra mappings that are available by default
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
  buf_set_keymap('n', '<Leader>q', '<cmd>lua require"my.diagnostics".setqflist()<CR>:cc 1<CR>')
  vim.cmd [[
    augroup LspDiagnostics
      autocmd! * <buffer>
      autocmd CursorHold * silent! lua vim.diagnostic.open_float { scope = "cursor", focus = false }
    augroup END
  ]]

  -- maybe worth learning to use gra from lsp-defaults instead?
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
