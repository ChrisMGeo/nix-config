# themes

Base16 color schemes that any host or user can use with Stylix. This folder sits outside `modules/`, so `machines.nix` does not load anything from it.

## Files

| File | What it does |
| --- | --- |
| `black-monochrome.nix` | A black and white scheme, with gray in place of the accent colors. Not used by anyone now. `chrismg` used it before switching to colors made from the wallpaper. |

## Rules

- Each file returns one Base16 scheme: a set with `scheme`, `author`, and `base00` to `base0F` as hex codes without the "#".
- To use a scheme, set `stylix.base16Scheme = import "${inputs.self}/themes/<file>.nix";` in a user's `theme.nix`. Without `base16Scheme`, Stylix makes the colors from `stylix.image`.
- Run `git add` on a new file. Nix ignores files that git does not track.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
