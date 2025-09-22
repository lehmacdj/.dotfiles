hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

local start_kitty_quick_access_terminal = function()
  local kitty_quick_access_app = hs.application.get("kitty-quick-access")
  local options =  {
    "quick-access-terminal",
    "--detach",
  }
  if kitty_quick_access_app then
    table.insert(options, "--override")
    table.insert(options, "output_name="..hs.mouse.getCurrentScreen():name())
  end
  local task = hs.task.new(
    "/opt/homebrew/bin/kitten",
    nil,
    options
  )
  task:setWorkingDirectory(os.getenv("HOME"))
  task:start()
end

hs.hotkey.bind({"control"}, "return", function()
  start_kitty_quick_access_terminal()
end)
