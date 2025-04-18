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

mod.rerequire = function(filename)
  local module_name = filename
    :gsub('^.*lua/', '') -- get rid of leading prefix
    :gsub('%.lua$', '') -- get rid of trailing .lua
    :gsub('/init$', '') -- get rid of (optional) trailing init.lua module
    :gsub('/', '.') -- replace / with . to make it a module name
  require('plenary.reload').reload_module(module_name)
  return require(module_name)
end

-- Function to check if cursor is in a markdown link URL
mod.is_cursor_in_markdown_link_url = function()
  -- Use vim.show_pos() to get all highlighter info at cursor position
  local pos_info = vim.inspect_pos(nil, nil, nil, {
    treesitter = true,
    syntax = false,
    extmarks = false,
    semantic_tokens = false
  })

  for _, item in ipairs(pos_info.treesitter or {}) do
    if item.capture == 'markup.link.url' then
      return true
    end
  end

  return false
end

return mod
