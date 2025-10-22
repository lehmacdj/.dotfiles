require('lualine').setup {
  sections = {
    lualine_b = {
      {
        function()
          local repo_dir = require('my.title').build_context().repo_dir
          if repo_dir then
            return '' .. repo_dir
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
  },
}
