---@type LazySpec
return {
  {
    "Yu-Leo/blame-column.nvim",
    cmd = "BlameColumnToggle",
    opts = {
      side = "left",
      -- default is cool-blue; make blame shades warmer (amber/orange)
      time_based_bg_opts = {
        hue = 28,
        saturation = 62,
        lightness_min = 12,
        lightness_max = 46,
      },
      window_opts = {
        number = false,
        relativenumber = false,
      },
    },
  },
}
