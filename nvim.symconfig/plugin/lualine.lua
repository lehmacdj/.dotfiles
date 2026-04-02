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
          local md = require('my.markdown')
          local mode = vim.fn.mode()
          if mode == 'v' or mode == 'V' or mode == '\22' then
            return md.visual_wordcount()
              .. '/' .. md.wordcount() .. ' words'
          end
          return md.wordcount() .. ' words'
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
