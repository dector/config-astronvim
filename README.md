# AstroNvim Template

**NOTE:** This is for AstroNvim v6+

## My Changes

Compared to the base AstroNvim template configuration, these are my repo changes:

- **Added `carderne/pi-nvim` plugin integration**
  - New plugin spec: `lua/plugins/pi-nvim.lua`
  - Configured with `require("pi-nvim").setup(opts)`
- **Added Pi-related keymaps** (`lua/plugins/pi_keymaps.lua`)
  - Normal mode:
    - `gp` → `:PiSend<CR>`
    - `<Leader>pv` → opens a vertical split terminal running `pi --extension npm:pi-nvim`
  - Visual mode:
    - `gp` → `:PiSendSelection<CR>`
- **Added navigation/reload keymaps** (`lua/plugins/pi_keymaps.lua`)
  - `J` → move down 5 lines (`5j`)
  - `K` → move up 5 lines (`5k`)
  - `gh` → hover diagnostics (`vim.diagnostic.open_float`)
  - `<Leader>aj` → join current line with next (`J`)
  - `<Leader>'r` → `:AstroReload<CR>`
- **Remapped find-related leader shortcuts** (`lua/plugins/pi_keymaps.lua`)
  - Disabled defaults:
    - `<Leader>ff`, `<Leader>fw`, `<Leader>fo`, `<Leader>fg`
  - Added replacements:
    - `<Leader>sf` → find files (`snacks.picker.files`)
    - `<Leader>sw` → find words (`snacks.picker.grep`)
    - `<Leader>so` → recent files (`snacks.picker.recent`)
    - `<Leader>sg` → git files (`snacks.picker.git_files`)
- **Added terminal escape keymap** (`lua/plugins/terminal_escape.lua`)
  - Terminal mode: `<C-\\><C-\\>` → exit terminal mode (`<C-\\><C-n>`)
- **Added project bookmarks feature** (`lua/plugins/bookmarks.lua`, `lua/utils/bookmarks.lua`)
  - `<Leader>ml` / `:BookmarkList` → list/search bookmarks in a Snacks picker with preview
  - `<Leader>ma` / `:BookmarkAdd` → add bookmark for current `file + line`
  - `<Leader>mA` / `:BookmarkRemove` → remove bookmark for current `file + line`
  - Storage: one JSON file per project under `stdpath("data") .. "/bookmarks"`

A template for getting started with [AstroNvim](https://github.com/AstroNvim/AstroNvim)

## 🛠️ Installation

#### Make a backup of your current nvim and shared folder

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

#### Create a new user repository from this template

Press the "Use this template" button above to create a new repository to store your user configuration.

You can also just clone this repository directly if you do not want to track your user configuration in GitHub.

#### Clone the repository

```shell
git clone https://github.com/<your_user>/<your_repository> ~/.config/nvim
```

#### Start Neovim

```shell
nvim
```
