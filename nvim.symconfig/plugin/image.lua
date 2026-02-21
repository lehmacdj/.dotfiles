require("image").setup {
  backend = "kitty",
  kitty_method = "normal",
  integrations = {
    markdown = {
      download_remote_images = false,
      resolve_image_path = function (document_path, image_path, fallback)
        -- image_path may be surrounded by <> in markdown; this is not
        -- handled by the default resolver
        local stripped_path = image_path:match("^<(.+)>$") or image_path
        -- Skip PDFs: multi-page PDFs cause ImageMagick to produce
        -- numbered output files (e.g. -source-0.png, -source-1.png)
        -- instead of the single file the plugin expects, crashing it
        if stripped_path:match("%.pdf$") then return nil end
        return fallback(document_path, stripped_path)
      end
    },
  },
}
