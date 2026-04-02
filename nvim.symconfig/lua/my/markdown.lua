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

local function count_words(lines)
  local count = 0
  for _, line in ipairs(lines) do
    -- %a matches letters only; optional ' and - allow
    -- contractions (don't) and hyphenated words (well-known)
    -- to count as single words
    for _ in line:gmatch("%a[%a'-]*") do
      count = count + 1
    end
  end
  return count
end

-- Count words in the current buffer, skipping YAML frontmatter.
mod.wordcount = function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local start = 1
  if lines[1] == '---' then
    for i = 2, #lines do
      if lines[i] == '---' then
        start = i + 1
        break
      end
    end
  end
  return count_words({unpack(lines, start)})
end

-- Count words in the visual selection.
mod.visual_wordcount = function()
  local s = vim.fn.line('v')
  local e = vim.fn.line('.')
  if s > e then s, e = e, s end
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  return count_words(lines)
end

return mod
