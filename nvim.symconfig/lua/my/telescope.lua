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
    attach_mappings = function(prompt_bufnr, map)
      local actions = require('telescope.actions')

      local function custom_open(action_fn)
        return function()
          action_fn(prompt_bufnr)
          vim.cmd('lcd ' .. vimhome)
        end
      end

      map({'i', 'n'}, '<CR>', custom_open(actions.select_default))
      map({'i', 'n'}, '<C-x>', custom_open(actions.select_horizontal))
      map({'i', 'n'}, '<C-v>', custom_open(actions.select_vertical))
      map({'i', 'n'}, '<C-t>', custom_open(actions.select_tab))

      return true
    end,
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
