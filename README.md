# 🎵 melody.nvim

melody.nvim is a Neovim plugin that allows you to search and play music tracks directly from your Neovim environment using the Telescope picker. It integrates with the `mpv` media player and provides a convenient way to search for and play music files without leaving your coding environment.

**NOTE**: this plugin is experimental and under development! 👷

## Features

- Search and play music tracks from within Neovim.
- Utilizes the `mpv` media player for seamless playback.
- Integrates with the Telescope picker for an interactive selection experience.
- Configurable music directory for easy customization.

## Installation

Install the required plugins using your preferred package manager. For example, using [Lazy](https://github.com/folke/lazy.nvim):

```lua
  {
    "whleucka/melody.nvim",
    requires = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim"
    },
    event = "LspAttach",
    keys = {
        { "<leader>mm", "<cmd>lua require('melody').music_search()<cr>)", desc = "Melody search" },
    },
    opts = {
      music_dir = "/path/to/your/music",
    }
  },
```

## Usage

1. Press `<leader>mm` to trigger the music search.
2. A Telescope picker will open with the list of available tracks from your configured music directory.
3. Navigate and select a track using the arrow keys or mouse.
4. Press `<Enter>` to play the selected track using `mpv`.

## Requirements

- Neovim (0.5+)
- `mpv` media player

## Troubleshooting

If you encounter any issues or have questions, feel free to [open an issue](https://github.com/whleucka/melody.nvim/issues) on the GitHub repository.

## License

This project is licensed under the [MIT License](LICENSE).
