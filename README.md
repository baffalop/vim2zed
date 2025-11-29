# Vim-2-Zed

A script for translating Vim mappings (vimrc) to Zed keymap format.

## Features

⚠️ **Status: WIP** ⚠️

- [x] Parse vim mappings
- [x] Parse Zed base keymap, keymap schema
- [x] Transform vim mappings to Zed keymap JSON stdout (via `SendKeystrokes`)
  - [x] Correct handling of special keys (mostly)
  - [ ] Proper support for `noremap`
- [ ] CLI: specify output file, various options
  - [ ] Ability to specify alternative default-keymap file
- [ ] Ability to merge mappings into pre-existing keymap
  - [ ] Warn about conflicts
- [ ] Build as Zed plugin??

## Usage

```bash
v2z input.vim
```

This will parse your Vim configuration file and output Zed keymap json that you can add to your Zed keymap file (`zed: open keymap file` ).

## Build from Source

### Prerequisites

- OCaml (≥ 4.14) + toolchain:
  - Opam package manager
  - Dune build system
  - See https://ocaml.org/docs/install.html for a setup guide

### Building

```bash
# Install dependencies
opam install . --deps-only

# Build the project
dune build

# Install locally (optional)
dune install
```

The executable will be available as `_build/default/bin/main.exe` or installed as `v2z` if you ran `dune install`.
