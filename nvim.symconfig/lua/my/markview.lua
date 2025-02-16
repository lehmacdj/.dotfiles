local mod = {}

-- would like to get this working, it seems very cool; a few things to figure
-- out though:
-- - [ ] color scheme: probably need to add highlight groups for treesitter
--   to the solarized colorscheme I use, wasn't able to base16-nvim's
--   solarized color scheme was ugly (though it did support treesitter better)
-- - [ ] figure out how to get comments hidden properly, the <!--wls-->
--   interferes with how this renders currently, I spent some time searching the
--   repo/docs and didn't find a way to alter their rendering
-- - [ ] figure out how to make lists not jump around, the list config I do here
--   doesn't prevent lists from indenting too much
mod.setup = function()
  local list_config = { add_padding = false, };
  require('markview').setup {
    preview = {
      -- see :h mode() for the modes available; this is all of them for now
      hybrid_modes = { '!', '', '', 'R', 'S', 'V', 'c', 'i', 'n', 'r', 's', 't', 'v' },
      edit_range = { 5, 5 },
    },
    markdown = {
      wrap = true,
      indent_size = 2,
      shift_width = 2,
      marker_minus = list_config,
      marker_plus = list_config,
      marker_star = list_config,
      marker_dot = list_config,
      marker_parenthesis = list_config,
    },
  }
end

return mod
