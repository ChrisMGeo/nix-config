# modules

Everything the flake builds. `machines.nix` reads the folder layout and builds each machine. The folders beside it hold the settings that it loads.

## Files

| File | What it does |
| --- | --- |
| `machines.nix` | Finds machines, hosts, and users from folder names. Builds every system and sets the flake outputs. |

## Subdirectories

- [features/](features/AGENTS.md): settings for every host.
- [machines/](machines/AGENTS.md): one folder per physical computer.

## Rules

- The loader depends on folder names. `machines`, `features`, `hosts`, `users`, and the platform names `nixos`, `darwin`, and `wsl` are fixed. If you rename one, update `machines.nix`, the README, and every `AGENTS.md` that names it.
- `machines.nix` accepts only the platform folder names `nixos`, `darwin`, and `wsl`. Any other name stops evaluation with an error.
- Keep machine-specific values out of `machines.nix`. Put them in a machine or host folder.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
