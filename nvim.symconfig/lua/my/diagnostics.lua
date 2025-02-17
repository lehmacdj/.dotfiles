local mod = {}

mod.configure = function()
  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = { severity = { "Error", }, },
    severity_sort = true,
  })
end

return mod
