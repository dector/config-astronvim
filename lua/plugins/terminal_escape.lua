---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        t = {
          ["<C-\\><C-\\>"] = { "<C-\\><C-n>", desc = "Exit terminal mode" },
        },
      },
    },
  },
}
