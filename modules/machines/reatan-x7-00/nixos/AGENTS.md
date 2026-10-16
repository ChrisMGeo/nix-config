# reatan-x7-00/nixos

Settings for every NixOS host on the machine `reatan-x7-00`. Each `.nix` file here loads for every host under `hosts/`. Today that is one host, `nixos`.

## Files

| File | What it does |
| --- | --- |
| `admin.nix` | Adds details to the login account `chrismg`, puts it in the `networkmanager` and `wheel` groups, and makes zsh its login shell. |
| `audio.nix` | Turns on PipeWire as the sound server and turns off PulseAudio. Lets Bluetooth audio only go out to headphones and speakers, so headphones that offer both directions get a speaker output. |
| `bluetooth.nix` | Turns on Bluetooth and runs bt-agent for each user, so pairings started from the Quickshell bar work. |
| `browsers.nix` | Installs Firefox for every user. |
| `desktop.nix` | Turns on the niri desktop, xwayland-satellite for X11 apps, the Soteria password prompt, and the PAM entry that lets swaylock unlock. |
| `form-factor.nix` | Marks this machine as a desktop with `machine.formFactor`. |
| `greeter.nix` | Turns on greetd with a Quickshell login screen that runs inside niri. Uses the Theme.qml of the Quickshell bar of the user `chrismg`, builds a Greeter.qml with that user's wallpaper and user name, builds niri settings with that user's cursor, and installs that font, Font Awesome, and the cursor for the whole system. |
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
