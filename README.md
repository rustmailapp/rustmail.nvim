<p align="center">
  <strong>rustmail.nvim</strong>
</p>

<p align="center">
  Neovim client for <a href="https://github.com/rustmailapp/rustmail">RustMail</a> — browse captured emails without leaving your editor.
</p>

<p align="center">
  <a href="#license"><img src="https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg" alt="License"></a>
</p>

## Requirements

- Neovim >= 0.10
- [`rustmail`](https://github.com/rustmailapp/rustmail) binary on PATH (or specify path in config)
- `curl` on PATH (only needed when `auto_start = true`)

## Install

**lazy.nvim**

```lua
{
  "rustmailapp/rustmail.nvim",
  cmd = "Rustmail",
  opts = {},
}
```

**packer.nvim**

```lua
use {
  "rustmailapp/rustmail.nvim",
  config = function()
    require("rustmail").setup()
  end,
}
```

## Configuration

```lua
require("rustmail").setup({
  host = "127.0.0.1",
  port = 8025,
  smtp_port = 1025,
  auto_start = false,
  binary = "rustmail",
  layout = "float",
  float = {
    width = 0.9,
    height = 0.9,
    border = "rounded",
  },
  toggle_keymap = "<leader>rm",
})
```

All options and their defaults: `:help rustmail-config`

## Usage

| Command              | Description                                |
|----------------------|--------------------------------------------|
| `:Rustmail`          | Open the TUI                               |
| `:Rustmail toggle`   | Toggle the TUI window                      |
| `:Rustmail close`    | Close the TUI window                       |
| `:Rustmail stop`     | Stop the auto-started daemon               |

### Keymaps

**Message List** — `<CR>` open, `dd` delete, `mr` toggle read, `ms` toggle star, `R` refresh, `/` search, `D` delete all, `q` close

**Message Detail** — `<BS>` back, `dd` delete, `mr` toggle read, `ms` toggle star, `gR` raw message, `ga` attachments, `gA` auth results, `q` close

Full keymap reference: `:help rustmail-keymaps`

## Documentation

- In-editor: `:help rustmail`
- Online: [rustmail docs](https://github.com/rustmailapp/rustmail/tree/master/docs)

## License

Licensed under either of:

- [MIT License](LICENSE-MIT)
- [Apache License, Version 2.0](LICENSE-APACHE)

at your option.
