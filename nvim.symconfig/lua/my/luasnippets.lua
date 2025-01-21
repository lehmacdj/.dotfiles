local mod = {}

local luasnip = require('luasnip')
local s = luasnip.snippet
local f = luasnip.function_node
local t = luasnip.text_node
local i = luasnip.insert_node
local time = require('my.time')

mod.load = function()
  -- if this gets significantly larger, we should move it to a separate file
  -- or use the loading instruction from here:
  -- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#lua
  luasnip.add_snippets('all', {
    s({
      trig = '@today',
      snippetType = 'autosnippet',
    }, {
      f(time.today_string),
    }),

    s({
      trig = '@tomorrow',
      snippetType = 'autosnippet',
    }, {
      f(time.tomorrow_string),
    }),

    s({
      trig = '@yesterday',
      snippetType = 'autosnippet',
    }, {
      f(time.yesterday_string),
    }),

    s({
      trig = '@now',
      snippetType = 'autosnippet',
    }, {
      f(time.hourminute_string),
    }),

    s({
      trig = '@isots',
      snippetType = 'autosnippet',
    }, {
      f(time.iso8601_timestamp_string),
    }),
  })

  function journal_note_snippet(trigger, time_factory)
    return
      s(trigger, {
        t('# '),
        f(time_factory),
        t({
          '',
          '',
          '## Log',
          '- ',
        }),
        i(1, 'details'),
      })
  end

  luasnip.add_snippets('markdown', {
    journal_note_snippet('#yesterday', time.yesterday_string),
    journal_note_snippet('#today', time.today_string),
    journal_note_snippet('#tomorrow', time.tomorrow_string),
  })
end

return mod
