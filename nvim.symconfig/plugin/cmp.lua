local cmp = require('cmp')
local Behavior = require('cmp.types').cmp.SelectBehavior
cmp.setup {
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  enabled = function()
    -- disable completion in comments
    local context = require 'cmp.config.context'
    local ok, ts_in_comment = pcall(context.in_treesitter_capture, 'comment')
    return not (ok and ts_in_comment)
      and not context.in_syntax_group('Comment')
      and vim.opt.filetype:get() ~= 'TelescopePrompt'
    end,
  mapping = {
    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-24), { 'i', 'c' }),
    ['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-12), { 'i', 'c' }),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(24), { 'i', 'c' }),
    ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(12), { 'i', 'c' }),
    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    ['<C-y>'] = cmp.config.disable,
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    ['<Down>'] = {
      i = cmp.mapping.select_next_item({ behavior = Behavior.Select }),
    },
    ['<Up>'] = {
      i = cmp.mapping.select_prev_item({ behavior = Behavior.Select }),
    },
    ['<C-n>'] = {
      i = cmp.mapping.select_next_item({ behavior = Behavior.Insert }),
    },
    ['<C-p>'] = {
      i = cmp.mapping.select_prev_item({ behavior = Behavior.Insert }),
    },
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp_signature_help' },
    { name = 'nvim_lsp' },
    {
      name = 'buffer',
      option = {
        get_bufnrs = function()
          return vim.api.nvim_list_bufs()
        end,
      },
    },
    { name = 'luasnip' },
    { name = 'path' },
    { name = 'cmp-pandoc-references' },
  })
}
