---@type LazySpec
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      opts.close_if_last_window = false
      opts.window = opts.window or {}
      opts.window.mappings = opts.window.mappings or {}

      -- Swap defaults: p = preview, P = paste
      opts.window.mappings["p"] = {
        "toggle_preview",
        config = {
          use_float = true,
          use_image_nvim = true,
        },
      }
      opts.window.mappings["P"] = "paste_from_clipboard"
    end,
  },
}
