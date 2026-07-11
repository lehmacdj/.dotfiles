local mod = {}

local frontmatter_ns = vim.api.nvim_create_namespace('markdown-frontmatter')

local function frontmatter_range(buf)
  local parser = vim.treesitter.get_parser(buf, 'markdown', { error = false })
  if not parser then return end

  local root = parser:parse()[1]:root()
  for child in root:iter_children() do
    local kind = child:type()
    if kind == 'minus_metadata' or kind == 'plus_metadata' then
      local start_row, _, end_row = child:range()
      return start_row, end_row
    end
  end
end

local function update_frontmatter_conceal(buf)
  vim.api.nvim_buf_clear_namespace(buf, frontmatter_ns, 0, -1)
  local start_row, end_row = frontmatter_range(buf)
  if not start_row then return end

  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  if cursor_row >= start_row and cursor_row < end_row then return end

  vim.api.nvim_buf_set_extmark(buf, frontmatter_ns, start_row, 0, {
    end_row = end_row,
    end_col = 0,
    conceal_lines = '',
  })
end

-- 'concealcursor' reveals only its current line. Remove the mark while the
-- cursor is anywhere in frontmatter so the complete block becomes visible.
mod.setup_frontmatter_conceal = function()
  local buf = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup(
    'MarkdownFrontmatter' .. buf,
    { clear = true }
  )
  vim.api.nvim_create_autocmd({
    'CursorMoved',
    'CursorMovedI',
    'TextChanged',
    'TextChangedI',
  }, {
    group = group,
    buffer = buf,
    callback = function() update_frontmatter_conceal(buf) end,
  })
  update_frontmatter_conceal(buf)
end

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
  -- skip fenced code blocks: ```...``` or ~~~...~~~
  local fence = nil
  for _, line in ipairs(lines) do
    local bt = line:match('^%s*```+')
    local tl = line:match('^%s*~~~+')
    if fence == nil and (bt or tl) then
      fence = bt and '`' or '~'
    elseif fence == '`' and bt then
      fence = nil
    elseif fence == '~' and tl then
      fence = nil
    elseif fence == nil then
      -- strip image alt text: ![alt text](url) -> ![](url)
      line = line:gsub('!%[(.-)%]', '![]')
      -- strip wikilink target: [[target|display]] -> [[display]]
      line = line:gsub('%[%[[^%]|]*|', '[[')
      -- strip markdown link URL: [text](url) -> [text]
      -- (also drops the url from images, alt was stripped above)
      line = line:gsub('(%b[])%b()', '%1')
      -- strip HTML tags
      line = line:gsub('<[^>]+>', '')
      -- strip footnote labels: [^label]
      line = line:gsub('%[%^[^%]]+%]', '')
      for _ in line:gmatch("%a[%a'-]*") do
        count = count + 1
      end
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
