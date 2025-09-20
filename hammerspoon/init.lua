hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.hotkey.bind({"control"}, "return", function()
  hs.task.new(
    "/opt/homebrew/bin/kitten",
    nil,
    {
      "quick-access-terminal",
      "--detach",
      "--override",
      "output_name="..hs.mouse.getCurrentScreen():name(),
    }
  ):start()
end)
