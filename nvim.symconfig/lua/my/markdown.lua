local mod = {}

local function redraw_markdown_bufs()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].filetype == 'markdown'
    then
      vim.treesitter.stop(buf)
      vim.treesitter.start(buf, 'markdown')
    end
  end
end

-- Toggle HTML comment concealing via the #md-comments-concealed?
-- treesitter predicate (plugin/treesitter-predicates.lua).
-- Bound to yoc/[oc/]oc in after/ftplugin/markdown.vim.
mod.show_comments = function()
  vim.g.show_markdown_comments = true
  redraw_markdown_bufs()
end

mod.hide_comments = function()
  vim.g.show_markdown_comments = false
  redraw_markdown_bufs()
end

return mod
