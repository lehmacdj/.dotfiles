local mod = {}

mod.today_string = function()
  return os.date('%Y-%m-%d')
end

mod.tomorrow_string = function()
  return os.date('%Y-%m-%d', os.time() + 86400)
end

mod.yesterday_string = function()
  return os.date('%Y-%m-%d', os.time() - 86400)
end

mod.hourminute_string = function()
  return os.date('%H:%M')
end

mod.iso8601_timestamp_string = function()
  return os.date('%Y-%m-%dT%H:%M:%SZ')
end

return mod
