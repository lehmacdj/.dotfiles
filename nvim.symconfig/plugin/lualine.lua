require('lualine').setup {
  sections = {
    lualine_b = {
      {
        function()
          local repo_dir = require('my.title').build_context().repo_dir
          if repo_dir then
            return ' ' .. repo_dir
          else
            return ''
          end
        end
      },
      'diff',
      'diagnostics'
    },
    lualine_x = {
      {
        'lsp_status',
        symbols = {
          spinner = { '◐', '◓', '◑', '◒', },
          separator = '',
        },
        ignore_lsp = {'null-ls', 'GitHub Copilot'},
        show_name = false,
      },
      'filetype',
    },
    lualine_z = {
      {
        function()
          local wc = vim.fn.wordcount()
          if wc.visual_words then
            return wc.visual_words .. '/' .. wc.words .. ' words'
          else
            return wc.words .. ' words'
          end
        end,
        cond = function()
          return vim.bo.filetype == 'markdown'
        end,
      },
      {
        'location',
        cond = function()
          return vim.bo.filetype ~= 'markdown'
        end,
      },
    },
  },
}
