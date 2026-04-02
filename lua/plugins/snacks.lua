---@type LazySpec
return {
  {
    "folke/snacks.nvim",
    opts = {
      zen = {
        toggles = {
          git_signs = true,
          mini_diff_signs = true,
        },
        win = {
          wo = {
            number = true,
            relativenumber = false,
            signcolumn = "yes",
          },
        },
      },
    },
  },
}
