# diesel.nvim

Neovim support for **Diesel**, the C-like text format used by the
[Petroleum](https://github.com/graphicmismatch/Petroleum) synthesizer for patches
(`.dsl` files).

One plugin, both halves:

- **[diesel-treesitter](https://github.com/graphicmismatch/diesel-treesitter)** - the
  grammar, compiled by nvim-treesitter, for highlighting, folds and text objects.
- **[diesel-lsp](https://github.com/graphicmismatch/diesel-lsp)** - the language server,
  for diagnostics, completion, hover, go-to-definition, document symbols and rename.

Both are fetched from GitHub on first use. The server is dependency-free Node, so
cloning it *is* the install: no npm, no build step.

## Install

### lazy.nvim

```lua
{
  "graphicmismatch/diesel.nvim",
  ft = "diesel",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {},
}
```

### packer

```lua
use {
  "graphicmismatch/diesel.nvim",
  requires = { "nvim-treesitter/nvim-treesitter" },
  config = function() require("diesel").setup() end,
}
```

Open a `.dsl` file and the plugin clones the server, registers the grammar (which
nvim-treesitter then compiles) and attaches. `:checkhealth diesel` reports on all of it.

Requirements: Neovim 0.10+, `node` 18+ and `git` on `PATH`, a C compiler for the
grammar, and nvim-treesitter for highlighting.

## What you get

| | |
| --- | --- |
| Diagnostics | Syntax errors, unknown node types and ports, duplicate node names, unknown references, an input driven twice, missing/duplicate `Audio Out`, macros not on a `Constant` |
| Completion | Node types, a node's ports after `.` (outputs before `->`, inputs after), port values and fields inside a node body, waveform names in an `Oscillator` |
| Hover | A node type's ports with their defaults |
| Go to definition | From a connection end or macro target to the node declaration |
| Document symbols | Patch, nodes with types, macros, nested subpatches |
| Rename | A node name and every reference to it |
| Highlighting | Via tree-sitter, with folds and locals queries |
| `gcc` | `commentstring` is `// %s` |

Completion arrives through the LSP, so it shows up in whatever completion engine you
already use (nvim-cmp, blink.cmp, or the built-in `vim.lsp.completion`). The plugin
picks up nvim-cmp's or blink.cmp's capabilities automatically when they are installed.

## Configuration

Defaults:

```lua
require("diesel").setup {
  lsp = {
    enable = true,
    url = "https://github.com/graphicmismatch/diesel-lsp",
    branch = "master",
    path = nil,          -- use a local checkout instead of cloning
    config = {},         -- merged into the vim.lsp.config entry
    auto_install = true, -- clone on the first .dsl file
  },
  treesitter = {
    enable = true,
    url = "https://github.com/graphicmismatch/diesel-treesitter",
    branch = "master",
    path = nil,          -- use a local checkout instead of cloning
    auto_install = true, -- compile on the first .dsl file
  },
  filetype = true,       -- map the .dsl extension to the diesel filetype
}
```

Working on the grammar or the server? Point at your checkouts:

```lua
require("diesel").setup {
  lsp = { path = "~/dev/diesel-lsp" },
  treesitter = { path = "~/dev/diesel-treesitter" },
}
```

## Commands

| Command | |
| --- | --- |
| `:DieselInstall` | Clone the language server |
| `:DieselUpdate` | Pull the server, `TSUpdate` the grammar, restart attached clients |
| `:DieselInfo` | Print where the server, parser and node binary are |
| `:checkhealth diesel` | Check every requirement |

## Keymaps

None are set: the server speaks standard LSP, so your existing `K`, `gd`, `gr`,
`<leader>rn` and diagnostic mappings work. Neovim 0.11+ maps `K`, `grn`, `gra` and
`gri` out of the box.

## A note on the queries

`queries/diesel/*.scm` are copies of the grammar repository's queries, because Neovim
looks for queries on the runtimepath under `queries/<lang>/` and the parser repo that
nvim-treesitter clones is not on it. `scripts/sync-queries.sh` re-copies them after a
grammar change.

## Tests

```sh
nvim --headless -u NONE -c 'lua dofile("test/run.lua")'
```

It clones the server, opens a `.dsl` file and checks filetype, attach, diagnostics,
completion, hover, grammar compilation and highlighting. Set `DIESEL_LSP_URL` and
`DIESEL_TS_URL` to local checkouts to run it without network, and `DIESEL_TS_PLUGIN` to
an nvim-treesitter checkout for the grammar half.

## Licence

MIT.
