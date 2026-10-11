# features/nixos

Settings for NixOS hosts. These files load on top of the shared `features/*.nix` files, and only for NixOS hosts. The `wsl` platform counts as NixOS too.

## Files

| File | What it does |
| --- | --- |
| `base.nix` | Turns on NetworkManager and sets the US English locale. |

## Rules

- Put only NixOS options here. An option from nix-darwin does not exist on NixOS, so it fails.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
