local mod = {}

-- looking for toggle autoformat? Either do:
-- vim.g.do_lsp_autoformat = not vim.g.do_lsp_autoformat
-- if feedback isn't important, or otherwise follow the guide of the yo= mapping
-- which first checks and alternately executes disable / enable to give better
-- feedback
mod.disable_autoformat = function()
  vim.g.do_autoformat = false
end
mod.enable_autoformat = function()
  vim.g.do_autoformat = true
end

return mod
