# reatan-x7-00/nixos/greeter

The login screen. `../greeter.nix` copies these files into the Nix store and starts them through greetd. machines.nix does not load this folder, because it holds no `.nix` files.

## Files

| File | What it does |
| --- | --- |
| `shell.qml` | The Quickshell login screen: the blurred wallpaper, the clock card, the user name and password form, and restart and shut down buttons that need a second click. Talks to greetd through `Quickshell.Services.Greetd`. |
| `niri.kdl` | The niri settings for the login screen. Skips the shortcut overlay, sets the cursor, and starts Quickshell, then quits niri when Quickshell exits. `../greeter.nix` fills in the words between `@` signs. |

## Rules

- `../greeter.nix` generates `Theme.qml` next to `shell.qml`. Every color, size, and path that `shell.qml` uses must be a property there.
- The look follows the desktop bar in `../hosts/nixos/users/chrismg/quickshell/`. When you change a shared size or color in the bar's `Theme.qml`, change it in `../greeter.nix` too.
- The login screen runs as the `greeter` account, not as a user. It can only use fonts, cursors, and programs installed for the whole system or named by store path.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
