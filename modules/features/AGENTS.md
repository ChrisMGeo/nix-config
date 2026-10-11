# features

Settings for every host. Each `.nix` file directly in this folder loads for every platform, NixOS and darwin alike.

## Files

| File | What it does |
| --- | --- |
| `base.nix` | Allows unfree packages, turns on flakes, sets the time zone, and installs `vim` and `git` for every user. |

## Subdirectories

- [nixos/](nixos/AGENTS.md): loaded only for NixOS hosts.

## Rules

- Put a setting here only if it is valid on every platform. An option that only NixOS defines, such as `services.printing`, breaks darwin evaluation. Put NixOS-only settings in `nixos/`.
- No darwin host exists yet, so nothing has checked this folder against darwin.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
