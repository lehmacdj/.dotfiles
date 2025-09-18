hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.hotkey.bind({"cmd", "ctrl"}, "return", function()
  hs.task.new("/opt/homebrew/bin/kitten", nil, {"quick-access-terminal", "--detach"}):start()
end)
