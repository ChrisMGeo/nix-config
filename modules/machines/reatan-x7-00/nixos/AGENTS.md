# reatan-x7-00/nixos

Settings for every NixOS host on the machine `reatan-x7-00`. Each `.nix` file here loads for every host under `hosts/`. Today that is one host, `nixos`.

## Files

| File | What it does |
| --- | --- |
| `admin.nix` | Adds details to the login account of every user folder: its full name (from a table keyed by folder name), the `networkmanager` and `wheel` groups, and zsh as its login shell. |
| `audio.nix` | Turns on PipeWire as the sound server and turns off PulseAudio. Lets Bluetooth audio only go out to headphones and speakers, so headphones that offer both directions get a speaker output. |
| `bluetooth.nix` | Turns on Bluetooth and defines a per-user bt-agent service, so pairings started from the Quickshell bar work. The service does not start at login. The bar starts it while a scan or a pairing from the bar runs, and stops it afterward. |
| `browsers.nix` | Installs Firefox for every user. |
| `desktop.nix` | Turns on the niri desktop, xwayland-satellite for X11 apps, the Soteria password prompt, the PAM entry that lets swaylock unlock, gpu-screen-recorder, which the user's Vicinae extension starts and stops, and gvfs and udisks2, which the file manager needs for the Trash and removable drives. |
| `form-factor.nix` | Marks this machine as a desktop with `machine.formFactor`. |
| `greeter.nix` | Turns on greetd with a Quickshell login screen that runs inside niri. Uses the Theme.qml of the Quickshell bar of the first user folder (`chrismg` today), builds a Greeter.qml with that user's wallpaper and user name, builds niri settings with that user's cursor, and installs that font, Font Awesome, and the cursor for the whole system. Exposes its niri config and QML under `system.build` so `modules/checks.nix` can check them. |
| `keyboard.nix` | Sets the US keyboard layout for the console and the desktop. |
| `power.nix` | Turns on UPower and power-profiles-daemon, and turns off sleep. |
| `printing.nix` | Turns on CUPS printing. |

## Subdirectories

- [greeter/](greeter/AGENTS.md): the QML file and niri settings for the login screen.
- [hosts/](hosts/AGENTS.md): one folder per host.

## Rules

- Put a setting here if every host on this machine needs it. Put it in `hosts/<host>/` if only one host needs it.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
