# chrismg

Home Manager settings for the user `chrismg` on the host `nixos`.

## Files

| File | What it does |
| --- | --- |
| `browser.nix` | Makes Brave the default browser for web pages and links through `~/.config/mimeapps.list`, and sets `BROWSER` to `brave` for terminal programs. Also lists the link handlers for Claude Code, Vesktop, and T3 Code, because Home Manager now owns that file and replaces the hand-written one. |
| `default.nix` | Installs packages for this user only: Codex, OpenCode, Claude Code, T3 Code, Brave, fastfetch, and Vesktop. |
| `devbox.nix` | Installs Devbox from nixpkgs-unstable for per-project packages listed in a project's `devbox.json`, and direnv with nix-direnv, which loads a project's packages into zsh on `cd` once its `.envrc` is allowed. |
| `git.nix` | Sets up git through Home Manager in `~/.config/git/config`: the name and email on commits, `main` as the first branch of new repositories, rebase on pull, signing of every commit and tag with the SSH key `~/.ssh/id_ed25519` and an `allowed_signers` file to check those signatures, and the delta diff viewer as git's pager. Installs the GitHub CLI, `gh`, and makes git log in to github.com through it. Replaces the hand-written `~/.config/gh/config.yml`. |
| `kitty.nix` | Sets up the kitty terminal with an 80% opaque black background, frees Ctrl+Shift+Left and Right for zsh, and links its custom tab bar from `kitty/tab_bar.py`. |
| `lock.nix` | Sets up swaylock as the lock screen and swayidle to start it when the session is locked. There are no idle timers. |
| `look.nix` | Declares the shapes and spacing Stylix has no setting for, shared by niri windows, the notifications, the Vicinae launcher, and the Quickshell bar and login screen: `look.cornerRadius` (12) for the buttons and pictures inside the notifications, while windows, panels, and everything in Quickshell are square, `look.borderWidth` (1) for the outline of small controls in the bar, such as switches, slider knobs, and text boxes, `look.windowGap` (16) between niri windows, `look.screenMargin` (12) between the screen edges and the bar, its drawers, and the notifications, `look.topMargin` (8) above the bar and the notification side panel, and `look.glowSoftness` (12), `look.glowSpread` (6), and `look.glowAlpha` (40) for the soft light glow around the focused niri window and the Quickshell panels. A spread of half the softness keeps the glow square at the corners. Change a `default` to change it everywhere. |
| `niri.nix` | Writes `~/.config/niri/config.kdl`: layout, no window outline, a soft light glow around the focused window instead, with the sizes from `look.nix`, the blur behind kitty, the activity monitor, the Quickshell panels, the Vicinae launcher, and the swaync side panel, which blurs what is really behind each one rather than only the wallpaper, and every key binding, including a tap of Mod on its own, which shows the Quickshell bar and its open popup and gives them the keyboard, or hides them without closing anything, and Ctrl+Shift+Escape, which opens the Quickshell activity monitor, and Mod+T, which opens and closes the Quickshell clock. Makes the activity monitor, the clock, and the now-playing window float. |
| `nix-tools.nix` | Installs tools for Nix code: the nixd language server, the nixfmt formatter, the statix and deadnix linters, and nix-tree for browsing what a build depends on. |
| `notifications.nix` | Runs SwayNotificationCenter for notification popups and the notification panel, with square cards without outlines in the Stylix colors, see-through at the Stylix popup opacity, with text at the Stylix popup font size. |
| `quickshell.nix` | Runs the Quickshell bar from nixpkgs-unstable as a systemd user service, which stops the Bluetooth pairing agent from `bluetooth.nix` when the bar starts or stops, installs it from the `quickshell/` folder with the Font Awesome icon font, compiles `quickshell/glow.frag` to `glow.frag.qsb` with qsb from the same Qt, and generates its `Theme.qml`, which makes the panels see-through black at the Stylix popup opacity from `theme.nix`, is shared with the login screen in `greeter.nix` as `lib.quickshell.themeFile`, together with the `quickshell/` folder as `lib.quickshell.qmlDir`, and also holds the paths to cava and `quickshell/cava.conf` for the audio visualizer, to nmcli, to systemctl, loginctl, busctl, and niri, which the bar and the login screen start by these paths instead of from PATH, to a script that joins enterprise Wi-Fi networks, and to a script that reads processes, their GPU use, and sensors for the activity monitor. |
| `shell.nix` | Turns on zsh with Ctrl and Alt arrow keys for moving by word, Shift keys for selecting text, and the starship prompt. |
| `theme.nix` | Loads Stylix and sets the black monochrome color scheme, Iosevka for monospace text, Iosevka Aile for sans-serif text, Libron for serif text (packaged in the file from its GitHub release), 80% opacity for popups such as the launcher and the bar, the Papirus-Dark icon theme with grey folders, and the Bibata cursor. |
| `vicinae.nix` | Sets up the Vicinae app launcher from nixpkgs-unstable, which Mod+Space opens, and runs its server as a systemd user service. Installs nine extensions from the `vicinae-extensions` flake input: Niri, Nix, SuperGenPass, OTP, Kaomojis, Number converter, GPU Screen Recorder, Lorem Ipsum, and Reminders. Gives the Reminders extension the paths to Node.js and notify-send through the service's environment, and installs jq for the GPU Screen Recorder extension. |
| `wallpaper.nix` | Picks a picture from the root `wallpapers/` folder and uses it at full size, so it works on any monitor without a list of resolutions. Sets it as the Stylix wallpaper, and runs wpaperd to draw it behind the windows. swaylock also shows it. |
| `zed.nix` | Sets up the Zed editor from nixpkgs-unstable through Home Manager: its settings, such as font sizes, the Base16 Black Metal theme, and the git panel, the extensions Zed installs on start (Nix, HTML, and base16 for the Black Metal theme). Runs only the nixd language server for Nix files and turns off nil, which the Nix extension also starts but is not installed. Turns off all telemetry (crash reports, usage data, non-Zero-Data-Retention Anthropic requests, and Edit Prediction training data), turns off Edit Predictions and hides their status bar button, and hides the sign-in button in the title bar. Runs Claude Code in the agent panel through the Nix-built claude-agent-acp from the llm-agents flake, because the generic Linux build Zed downloads does not run on NixOS. Zed may still edit `settings.json`, and each rebuild merges these settings back in. Turns off the Stylix Zed target, so Zed keeps its own theme and fonts. |

`default.nix` takes Codex, OpenCode, Claude Code, and T3 Code from the llm-agents flake. It takes Brave, fastfetch, and Vesktop from the stable nixpkgs set.

## Subdirectories

- [kitty/](kitty/AGENTS.md): the custom kitty tab bar.
- [quickshell/](quickshell/AGENTS.md): the QML files for the Quickshell bar.

## Rules

- Add a package to `home.packages`. Items in a Nix list are separated by spaces, not commas.
- For a package from nixpkgs-unstable, take the `unstable` argument, as `zed.nix` does, and use `unstable.<name>`. `machines.nix` passes it to every Home Manager module, so do not define it again.
- Run the host's rebuild command to apply these settings. No separate command exists for Home Manager.
- Find package names at search.nixos.org.
- Put a tool that only one project needs in that project's `devbox.json` with `devbox add`, not in `home.packages`.
- `niri.nix` replaces niri's default settings completely. Add every key binding you want to its `binds` set. Check the result with `niri validate`.
- Add a Vicinae extension to `programs.vicinae.extensions` in `vicinae.nix` as `extensions.<folder>`, where `<folder>` is the extension's folder name in github.com/vicinaehq/extensions. Check its README for programs it runs, and install those too.
- Take colors from `config.lib.stylix.colors` instead of writing color codes, so every program keeps the same scheme.
- Add a Zed extension to `programs.zed-editor.extensions` in `zed.nix` by its id in github.com/zed-industries/extensions. Zed downloads it on its next start.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
