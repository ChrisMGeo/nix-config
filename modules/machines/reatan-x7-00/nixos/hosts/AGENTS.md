# hosts

One folder per host. The folder name becomes the host name, the network name, and the flake output name. Build a host with `sudo nixos-rebuild switch --flake .#<host>`.

## Subdirectories

- [nixos/](nixos/AGENTS.md): the host `nixos`.

## Rules

- Each host folder holds the files for its own hardware and boot. For new hardware, generate `hardware-configuration.nix` on that computer with `nixos-generate-config --show-hardware-config`.
- A host folder with no `users/` folder has no Home Manager users.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
