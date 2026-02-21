require("image").setup {
  backend = "kitty",
  kitty_method = "normal",
  integrations = {
    markdown = {
      download_remote_images = false,
      resolve_image_path = function (document_path, image_path, fallback)
        -- image_path may have be surrounded by <> in markdown; this is not
        -- handled by the default resolver
        local stripped_path = image_path:match("^<(.+)>$") or image_path
        return fallback(document_path, stripped_path)
      end
    },
  },
}
