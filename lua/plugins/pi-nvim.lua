---@type LazySpec
return {
  {
    "carderne/pi-nvim",
    opts = {},
    config = function(_, opts)
      require("pi-nvim").setup(opts)
    end,
  },
}
