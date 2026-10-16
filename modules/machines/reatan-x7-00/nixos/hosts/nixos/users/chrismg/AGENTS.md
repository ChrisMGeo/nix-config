# chrismg

Home Manager settings for the user `chrismg` on the host `nixos`.

## Files

| File | What it does |
| --- | --- |
| `default.nix` | Installs packages for this user only: Codex, OpenCode, Claude Code, Brave, fastfetch, and Zed. |
| `kitty.nix` | Sets up the kitty terminal with an 80% opaque black background, frees Ctrl+Shift+Left and Right for zsh, and links its custom tab bar from `kitty/tab_bar.py`. |
| `lock.nix` | Sets up swaylock as the lock screen and swayidle to start it when the session is locked. There are no idle timers. |
| `niri.nix` | Writes `~/.config/niri/config.kdl`: layout, window corners, the window outline (base03 when focused, a mix of base02 and base03 when not), the blur behind kitty and the Quickshell panels, and every key binding, including Mod+B, which pins the Quickshell bar on screen, and Ctrl+Shift+Escape, which opens the Quickshell activity monitor. Makes the activity monitor float. |
| `notifications.nix` | Runs SwayNotificationCenter for notification popups and the notification panel, with rounded, outlined cards in the Stylix colors. |
| `quickshell.nix` | Runs the Quickshell bar from nixpkgs-unstable as a systemd user service, installs it from the `quickshell/` folder with the Font Awesome icon font, and generates its `Theme.qml`, which makes the panels 80% opaque black and also holds the paths to cava and `quickshell/cava.conf` for the audio visualizer, to nmcli, to a script that joins enterprise Wi-Fi networks, and to a script that reads processes, their GPU use, and sensors for the activity monitor. |
| `shell.nix` | Turns on zsh with Ctrl and Alt arrow keys for moving by word, Shift keys for selecting text, and the starship prompt. |
| `theme.nix` | Loads Stylix and sets the black monochrome color scheme, the Iosevka fonts, the Papirus-Dark icon theme with grey folders, and the Bibata cursor. |
| `vicinae.nix` | Sets up the Vicinae app launcher and runs its server as a systemd user service. |
| `wallpaper.nix` | Picks a picture from the root `wallpapers/` folder, at build time shrinks it to the monitor's resolution, darkens its blacks, and sharpens it, sets it as the Stylix wallpaper, and runs wpaperd to draw it behind the windows. swaylock also shows it. |

`default.nix` takes Codex, OpenCode, and Claude Code from the llm-agents flake. It takes Zed from nixpkgs-unstable. It takes Brave and fastfetch from the stable nixpkgs set.

## Subdirectories

- [kitty/](kitty/AGENTS.md): the custom kitty tab bar.
- [quickshell/](quickshell/AGENTS.md): the QML files for the Quickshell bar.

## Rules

- Add a package to `home.packages`. Items in a Nix list are separated by spaces, not commas.
- Run the host's rebuild command to apply these settings. No separate command exists for Home Manager.
- Find package names at search.nixos.org.
- `niri.nix` replaces niri's default settings completely. Add every key binding you want to its `binds` set. Check the result with `niri validate`.
- Take colors from `config.lib.stylix.colors` instead of writing color codes, so every program keeps the same scheme.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
