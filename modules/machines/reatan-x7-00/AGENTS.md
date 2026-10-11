# reatan-x7-00

The physical machine named `reatan-x7-00`.

## Files

No `.nix` files sit directly in this folder. Settings for this machine live in `nixos/`.

## Subdirectories

- [nixos/](nixos/AGENTS.md): the NixOS platform, which holds the host `nixos`.

## Rules

- A `.nix` file added here loads for every platform on this machine. Add one only for settings that every platform needs. Otherwise, put it in `nixos/`.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
