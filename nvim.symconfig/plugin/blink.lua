local ok, blink = pcall(require, 'blink.cmp')
if not ok then
  return
end

blink.setup({
  enabled = function()
    if vim.bo.filetype == 'TelescopePrompt' then
      return false
    end

    local ok_context, context = pcall(require, 'blink.cmp.config.context')
    if not ok_context then
      return true
    end

    return not context.in_treesitter_capture('comment')
      and not context.in_syntax_group('Comment')
  end,
  snippets = { preset = 'luasnip' },
  keymap = {
    preset = 'default',
    ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<C-y>'] = { 'accept', 'fallback' },
    ['<C-j>'] = { 'accept', 'fallback' },
    ['<C-s>'] = { 'accept', 'fallback' },
    ['<Down>'] = { 'select_next', 'fallback' },
    ['<Up>'] = { 'select_prev', 'fallback' },
    ['<C-n>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback' },
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
  },
  completion = {
    menu = {
      auto_show = true,
      draw = {
        columns = {
          { 'label' },
          { 'kind_icon' },
          { 'label_description' },
        },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 150,
      update_delay_ms = 50,
    },
    ghost_text = {
      enabled = false,
    },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
})
