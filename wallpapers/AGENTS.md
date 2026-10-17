# wallpapers

Wallpaper pictures that any host or user can use. This folder sits outside `modules/`, so `machines.nix` does not load anything from it.

## Files

| File | What it does |
| --- | --- |
| `default.nix` | Maps each wallpaper's name to its picture. A module loads it with `import "${inputs.self}/wallpapers"`. |
| `monochrome-mountain-in-the-void.png` | A black and white drawing of a jagged, snowy mountain peak in the lower right of a black background, generated with GPT and upscaled to 3344x1882 with waifu2x. It has no wallhaven ID, so it is named after its title. Used by `chrismg` on the host `nixos`. |
| `wallhaven-1q2kd9.png` | A stylized black and white portrait of a woman with her head tilted back, on black, upscaled to 3840x2160 with waifu2x. Not used by anyone now. |
| `wallhaven-3kxgm9.png` | A black and white drawing of a dark figure standing in rippling water, looking up at planets and stars, upscaled to 3840x2160 with waifu2x. Not used by anyone now. |
| `wallhaven-5yzd29.png` | White cherry blossoms on black. Not used by anyone now. |
| `wallhaven-d88253.png` | A crowned knight with a red cloak and a raised sword, on black. Not used by anyone now. |
| `wallhaven-gwd987.jpg` | A photo of a pink cherry blossom branch on black. Not used by anyone now. |
| `wallhaven-oglrv9.jpg` | A photo of a snow-covered mountain peak in sunlight under a dark gray sky. Not used by anyone now. |

## Rules

- To add a wallpaper, put the picture here, add it to `default.nix`, and run `git add` on the picture. Nix ignores files that git does not track.
- Name a picture after where it came from, such as its wallhaven ID, not after the user who picks it. If it has no ID, use its title in lowercase words joined by hyphens.
- To pick a wallpaper for a user, set `stylix.image` in that user's `wallpaper.nix`. See `users/chrismg/wallpaper.nix`.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
