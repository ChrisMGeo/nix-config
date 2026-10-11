# users

One folder per user. The folder name is the login name. Each `.nix` file in a user folder is a Home Manager module. Home Manager sets up that user's packages and dotfiles. It does not change the whole system.

## Subdirectories

- [chrismg/](chrismg/AGENTS.md): Home Manager settings for `chrismg`.

## Rules

- Adding a folder here creates a normal login account with a home folder. Put account settings that affect the whole system in the platform's `admin.nix`, one level up from `hosts/`, in `reatan-x7-00/nixos/`.
- Do not put system-wide packages here. Use `modules/features/base.nix` or a platform file.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
