local mod = {}

mod.smart_send_to_qflist = function(prompt_bufnr)
  require('telescope.actions').smart_send_to_qflist(prompt_bufnr)
  vim.cmd('cc 1')
end

mod.find_vim_config_files = function()
  local vimhome = vim.fn.stdpath('config')
  require('telescope.builtin').find_files({
    prompt_title = 'nvim config files',
    hidden = true,
    cwd = vimhome,
    search_dirs = {
      vimhome .. '/lua/my',
      vimhome .. '/autoload/my',
      vimhome .. '/plugin',
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
