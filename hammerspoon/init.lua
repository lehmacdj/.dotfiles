hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

local start_kitty_quick_access_terminal = function()
  -- the kitty-quick-access app is a reliable way to detect whether the quick
  -- access terminal is already running
  local kitty_quick_access_app = hs.application.get("kitty-quick-access")
  local options =  {
    "quick-access-terminal",
    "--detach",
  }
  -- I've found that if --override output_name is specified the first time
  -- the quick access terminal is launched, it gets stuck on some screen, but
  -- if it is already running, output_name reliably causes the terminal to
  -- switch to the specified screen
  if kitty_quick_access_app then
    table.insert(options, "--override")
    table.insert(options, "output_name="..hs.mouse.getCurrentScreen():name())
  end
  local task = hs.task.new(
    "/Applications/kitty.app/Contents/MacOS/kitten",
    nil,
    options
  )
  task:setWorkingDirectory(os.getenv("HOME"))
  task:start()
end

hs.hotkey.bind({"control"}, "return", function()
  start_kitty_quick_access_terminal()
end)
