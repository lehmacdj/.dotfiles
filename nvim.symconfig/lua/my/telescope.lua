local mod = {}

mod.smart_send_to_qflist = function(prompt_bufnr)
  require('telescope.actions').close(prompt_bufnr)
  require('telescope.actions').smart_send_to_qflist(prompt_bufnr)
  vim.cmd('cc 1')
end

mod.custom_setup = function()
  require('telescope').setup {
    defaults = {
      mappings = {
        i = {
          ['<C-q>'] = mod.smart_send_to_qflist,
          ['<M-q>'] = false,
          ['<C-j>'] = 'move_selection_next',
          ['<C-n>'] = 'move_selection_next',
          ['<C-k>'] = 'move_selection_previous',
          ['<C-p>'] = 'move_selection_previous'
        },
        n = {
          ['<C-c>'] = 'close',
        },
      },
    },
    pickers = {
      buffers = {
        sort_lastused = true,
        mappings = {
          n = {
            ['d'] = require('telescope.actions').delete_buffer,
          },
        },
      },
    },
  }
  require('telescope').load_extension('fzf')
end

mod.find_vim_config_files = function()
  local vimhome = vim.fn.stdpath('config')
  require('telescope.builtin').find_files({
    prompt_title = 'nvim config files',
    hidden = true,
    cwd = vim.fn.stdpath('config'),
    search_dirs = {
      vimhome .. '/lua/my',
      vimhome .. '/autoload/my'
    },
  })
end

return mod
