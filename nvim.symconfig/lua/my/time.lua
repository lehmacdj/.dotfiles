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
  return os.date('!%Y-%m-%dT%H:%M:%SZ')
end

mod.local_timestamp_string = function()
  local now = os.time()
  local utc = os.date('!*t', now)
  local loc = os.date('*t', now)
  -- compute offset in minutes
  local diff = os.difftime(
    os.time(loc), os.time(utc)
  )
  local sign = diff >= 0 and '+' or '-'
  diff = math.abs(diff)
  local h = math.floor(diff / 3600)
  local m = math.floor((diff % 3600) / 60)
  return os.date('%Y-%m-%dT%H:%M:%S', now)
    .. string.format('%s%02d:%02d', sign, h, m)
end

return mod
