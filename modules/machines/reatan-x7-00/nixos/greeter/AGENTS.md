# reatan-x7-00/nixos/greeter

The login screen. `../greeter.nix` copies these files into the Nix store and starts them through greetd. machines.nix does not load this folder, because it holds no `.nix` files.

## Files

| File | What it does |
| --- | --- |
| `shell.qml` | The Quickshell login screen: the blurred wallpaper, the clock card, the user name and password form, and restart and shut down buttons that need a second click. Talks to greetd through `Quickshell.Services.Greetd`. |
| `niri.kdl` | The niri settings for the login screen. Skips the shortcut overlay, sets the cursor, and starts Quickshell, then quits niri when Quickshell exits. `../greeter.nix` fills in the words between `@` signs. |

## Rules

- `../greeter.nix` puts two files next to `shell.qml`: the bar's `Theme.qml`, shared by `../hosts/nixos/users/chrismg/quickshell.nix` as `lib.quickshell.themeFile`, and a generated `Greeter.qml`. Every color and size that `shell.qml` uses must come from `Theme`. Values only the login screen needs, such as the wallpaper, go in `Greeter.qml`.
- The look follows the desktop bar automatically, because the login screen uses the bar's `Theme.qml`. If you rename or remove a `Theme` property, check that `shell.qml` does not use it.
- The login screen runs as the `greeter` account, not as a user. It can only use fonts, cursors, and programs installed for the whole system or named by store path.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
