local mod = {}

mod.configure = function()
  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    severity_sort = true,
  })
end

return mod
