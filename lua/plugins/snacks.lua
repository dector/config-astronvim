---@type LazySpec
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts = opts or {}

      opts.zen = vim.tbl_deep_extend("force", opts.zen or {}, {
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
      })

      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
        format = function(item, picker)
          if not item.file then return {} end

          local ret = {}
          local path = Snacks.picker.util.path(item) or item.file

          if picker.opts.icons.files.enabled ~= false then
            local icon, hl = Snacks.util.icon(path, item.dir and "directory" or "file", {
              fallback = picker.opts.icons.files,
            })
            icon = Snacks.picker.util.align(icon, picker.opts.formatters.file.icon_width or 2)
            ret[#ret + 1] = { icon, hl, virtual = true }
          end

          ret[#ret + 1] = {
            "",
            resolve = function(max_width)
              local truncpath = Snacks.picker.util.truncpath(
                path,
                math.max(max_width, picker.opts.formatters.file.min_width or 20),
                { cwd = picker:cwd(), kind = picker.opts.formatters.file.truncate }
              )
              local dir, base = truncpath:match "^(.*)/(.+)$"
              if base and dir then
                return {
                  { base, "SnacksPickerFile", field = "file" },
                  { " · ", "SnacksPickerDimmed" },
                  { dir, "SnacksPickerDir", field = "file" },
                }
              end
              return { { truncpath, "SnacksPickerFile", field = "file" } }
            end,
          }

          return ret
        end,
      })
    end,
  },
}
