# wallpapers

Wallpaper pictures that any host or user can use. This folder sits outside `modules/`, so `machines.nix` does not load anything from it.

## Files

| File | What it does |
| --- | --- |
| `default.nix` | Maps each wallpaper's name to its picture. A module loads it with `import "${inputs.self}/wallpapers"`. |
| `wallhaven-5yzd29.png` | White cherry blossoms on black. Used by `chrismg` on the host `nixos`. |
| `wallhaven-gwd987.jpg` | A photo of a pink cherry blossom branch on black. Not used by anyone yet. |

## Rules

- To add a wallpaper, put the picture here, add it to `default.nix`, and run `git add` on the picture. Nix ignores files that git does not track.
- Name a picture after where it came from, such as its wallhaven ID, not after the user who picks it.
- To pick a wallpaper for a user, set `stylix.image` in that user's `wallpaper.nix`. See `users/chrismg/wallpaper.nix`.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
