# chrismg/kitty

Files for the kitty terminal of the user `chrismg`. These files are not Nix modules, so the loader does not read them. `../kitty.nix` links them into `~/.config/kitty`.

## Files

| File | What it does |
| --- | --- |
| `tab_bar.py` | The custom tab bar. Draws each tab as a separate rounded capsule with Powerline edge glyphs. |

## Rules

- `tab_bar.py` contains Powerline glyphs from the Unicode private use area. Edit it with a tool that keeps those characters unchanged.
- kitty reads this file only because `tab_bar_style` is "custom" in `../kitty.nix`.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
