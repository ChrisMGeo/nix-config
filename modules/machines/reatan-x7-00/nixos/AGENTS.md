# reatan-x7-00/nixos

Settings for every NixOS host on the machine `reatan-x7-00`. Each `.nix` file here loads for every host under `hosts/`. Today that is one host, `nixos`.

## Files

| File | What it does |
| --- | --- |
| `admin.nix` | Adds details to the login account `chrismg`, puts it in the `networkmanager` and `wheel` groups, and makes zsh its login shell. |
| `audio.nix` | Turns on PipeWire as the sound server and turns off PulseAudio. |
| `browsers.nix` | Installs Firefox for every user. |
| `desktop.nix` | Turns on the niri desktop, the greetd login screen with tuigreet, and the Soteria password prompt. |
| `form-factor.nix` | Marks this machine as a desktop with `machine.formFactor`. |
| `keyboard.nix` | Sets the US keyboard layout for the console and the desktop. |
| `printing.nix` | Turns on CUPS printing. |

## Subdirectories

- [hosts/](hosts/AGENTS.md): one folder per host.

## Rules

- Put a setting here if every host on this machine needs it. Put it in `hosts/<host>/` if only one host needs it.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
