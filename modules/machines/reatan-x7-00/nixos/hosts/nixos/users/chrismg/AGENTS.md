# chrismg

Home Manager settings for the user `chrismg` on the host `nixos`.

## Files

| File | What it does |
| --- | --- |
| `default.nix` | Installs packages for this user only: Codex, OpenCode, Claude Code, Brave, and Zed. |
| `kitty.nix` | Sets up the kitty terminal and links its custom tab bar from `kitty/tab_bar.py`. |
| `shell.nix` | Turns on zsh and the starship prompt. |
| `theme.nix` | Loads Stylix and sets the black monochrome color scheme and the Iosevka fonts. |

`default.nix` takes Codex, OpenCode, and Claude Code from the llm-agents flake. It takes Zed from nixpkgs-unstable. It takes Brave from the stable nixpkgs set.

## Subdirectories

- [kitty/](kitty/AGENTS.md): the custom kitty tab bar.

## Rules

- Add a package to `home.packages`. Items in a Nix list are separated by spaces, not commas.
- Run the host's rebuild command to apply these settings. No separate command exists for Home Manager.
- Find package names at search.nixos.org.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
