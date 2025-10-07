local mod = {}

mod.configure = function()
  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = { severity = { vim.diagnostic.severity.ERROR, }, },
    severity_sort = true,
  })
end

mod.setqflist = function()
  local errorDiagnostics = vim.diagnostic.get(
    nil,
    {severity=vim.diagnostic.severity.ERROR}
  )
  if #errorDiagnostics == 0 then
    vim.diagnostic.setqflist { open = false }
  else
    vim.diagnostic.setqflist {
      open = false,
      severity = { min = vim.diagnostic.severity.ERROR }
    }
  end
end

return mod
