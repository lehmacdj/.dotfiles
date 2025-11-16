local my_telescope = require('my.telescope')

require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-q>'] = my_telescope.smart_send_to_qflist,
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
          ['dd'] = require('telescope.actions').delete_buffer,
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
