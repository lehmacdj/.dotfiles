local mod = {}

mod.show_comments = function()
  vim.g.show_markdown_comments = true
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].filetype == 'markdown'
    then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd('syntax clear htmlCommentConceal')
      end)
    end
  end
end

mod.hide_comments = function()
  vim.g.show_markdown_comments = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].filetype == 'markdown'
    then
      vim.api.nvim_buf_call(buf, function()
        pcall(vim.cmd, 'syntax clear htmlCommentConceal')
        vim.cmd(
          'syntax region htmlCommentConceal'
          .. ' matchgroup=htmlCommentConcealDelimiters'
          .. ' start="<!--" end="-->" conceal'
        )
      end)
    end
  end
end

return mod
