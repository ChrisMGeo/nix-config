# chrismg

Home Manager settings for the user `chrismg` on the host `nixos`.

## Files

| File | What it does |
| --- | --- |
| `browser.nix` | Makes Brave the default browser for web pages and links through `~/.config/mimeapps.list`, and sets `BROWSER` to `brave` for terminal programs. Also lists the link handlers for Claude Code, Vesktop, and T3 Code, because Home Manager now owns that file and replaces the hand-written one. |
| `default.nix` | Installs packages for this user only: Codex, OpenCode, Claude Code, T3 Code, Brave, fastfetch, Vesktop, and Zed. |
| `kitty.nix` | Sets up the kitty terminal with an 80% opaque black background, frees Ctrl+Shift+Left and Right for zsh, and links its custom tab bar from `kitty/tab_bar.py`. |
| `lock.nix` | Sets up swaylock as the lock screen and swayidle to start it when the session is locked. There are no idle timers. |
| `look.nix` | Declares the shapes and spacing Stylix has no setting for, shared by niri windows, the notifications, the Vicinae launcher, and the Quickshell bar and login screen: `look.cornerRadius` (12) for the buttons, rows, and other parts inside windows and panels, which themselves are square, `look.borderWidth` (1) for the outline of small controls in the bar, such as switches, slider knobs, and text boxes, `look.windowGap` (16) between niri windows, `look.screenMargin` (12) between the screen edges and the bar, its drawers, and the notifications, and `look.topMargin` (8) above the bar and the notification side panel. Change a `default` to change it everywhere. |
| `niri.nix` | Writes `~/.config/niri/config.kdl`: layout, no window outline, a soft light glow around the focused window instead, the blur behind kitty, the activity monitor, the Quickshell panels, the Vicinae launcher, and the swaync side panel, which blurs what is really behind each one rather than only the wallpaper, and every key binding, including Mod+B, which pins the Quickshell bar on screen, and Ctrl+Shift+Escape, which opens the Quickshell activity monitor, and Mod+T, which opens and closes the Quickshell clock. Makes the activity monitor, the clock, and the now-playing window float. |
| `notifications.nix` | Runs SwayNotificationCenter for notification popups and the notification panel, with square cards without outlines in the Stylix colors, see-through at the Stylix popup opacity, with text at the Stylix popup font size. |
| `quickshell.nix` | Runs the Quickshell bar from nixpkgs-unstable as a systemd user service, installs it from the `quickshell/` folder with the Font Awesome icon font, and generates its `Theme.qml`, which makes the panels see-through black at the Stylix popup opacity from `theme.nix`, is shared with the login screen in `greeter.nix` as `lib.quickshell.themeFile`, and also holds the paths to cava and `quickshell/cava.conf` for the audio visualizer, to nmcli, to systemctl for the Bluetooth pairing agent, to a script that joins enterprise Wi-Fi networks, and to a script that reads processes, their GPU use, and sensors for the activity monitor. |
| `shell.nix` | Turns on zsh with Ctrl and Alt arrow keys for moving by word, Shift keys for selecting text, and the starship prompt. |
| `theme.nix` | Loads Stylix and sets the black monochrome color scheme, Iosevka for monospace text, Iosevka Aile for sans-serif text, Libron for serif text (packaged in the file from its GitHub release), 80% opacity for popups such as the launcher and the bar, the Papirus-Dark icon theme with grey folders, and the Bibata cursor. |
| `vicinae.nix` | Sets up the Vicinae app launcher from nixpkgs-unstable and runs its server as a systemd user service. Installs nine extensions from the `vicinae-extensions` flake input: Niri, Nix, SuperGenPass, OTP, Kaomojis, Number converter, GPU Screen Recorder, Lorem Ipsum, and Reminders. Gives the Reminders extension the paths to Node.js and notify-send through the service's environment, and installs jq for the GPU Screen Recorder extension. |
| `wallpaper.nix` | Picks a picture from the root `wallpapers/` folder and uses it at full size, so it works on any monitor without a list of resolutions. Sets it as the Stylix wallpaper, and runs wpaperd to draw it behind the windows. swaylock also shows it. |

`default.nix` takes Codex, OpenCode, Claude Code, and T3 Code from the llm-agents flake. It takes Zed from nixpkgs-unstable. It takes Brave, fastfetch, and Vesktop from the stable nixpkgs set.

## Subdirectories

- [kitty/](kitty/AGENTS.md): the custom kitty tab bar.
- [quickshell/](quickshell/AGENTS.md): the QML files for the Quickshell bar.

## Rules

- Add a package to `home.packages`. Items in a Nix list are separated by spaces, not commas.
- Run the host's rebuild command to apply these settings. No separate command exists for Home Manager.
- Find package names at search.nixos.org.
- `niri.nix` replaces niri's default settings completely. Add every key binding you want to its `binds` set. Check the result with `niri validate`.
- Add a Vicinae extension to `programs.vicinae.extensions` in `vicinae.nix` as `extensions.<folder>`, where `<folder>` is the extension's folder name in github.com/vicinaehq/extensions. Check its README for programs it runs, and install those too.
- Take colors from `config.lib.stylix.colors` instead of writing color codes, so every program keeps the same scheme.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
