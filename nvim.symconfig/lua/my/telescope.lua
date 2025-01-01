local mod = {}

mod.smart_send_to_qflist = function(prompt_bufnr)
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
      find_files = {
        mappings = {
          i = { ['<CR>'] = require('telescope.actions').select_drop },
          n = { ['<CR>'] = require('telescope.actions').select_drop },
        },
      },
      live_grep = {
        mappings = {
          i = { ['<CR>'] = require('telescope.actions').select_drop },
          n = { ['<CR>'] = require('telescope.actions').select_drop },
        },
      },
      grep_string = {
        mappings = {
          i = { ['<CR>'] = require('telescope.actions').select_drop },
          n = { ['<CR>'] = require('telescope.actions').select_drop },
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
    cwd = vimhome,
    search_dirs = {
      vimhome .. '/lua/my',
      vimhome .. '/autoload/my'
    },
  })
end

mod.find_dotfiles = function()
  require('telescope.builtin').find_files({
    prompt_title = 'dotfiles',
    hidden = true,
    cwd = os.getenv('DOTFILES'),
    search_dirs = { os.getenv('DOTFILES') },
  })
end

return mod
