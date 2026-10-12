# nix-config

This repository describes the operating system and user setup for the computers it manages. Nix builds each system from these files. Given the same pinned versions in `flake.lock`, the same files always produce the same system.

Today the repository manages one computer, `reatan-x7-00`, with one NixOS host named `nixos`. That host runs the niri desktop with a Quickshell bar, the Vicinae launcher, SwayNotificationCenter, and the kitty terminal, themed by Stylix. It also has PipeWire audio, Firefox, Brave, the Zed editor, zsh with starship, and three AI coding agents: Codex, OpenCode, and Claude Code.

New to Nix? Read the glossary below first. Then read the layout and the loading order. Coding agents should start at [AGENTS.md](AGENTS.md).

## Words you need to know

| Term | Meaning in this repository |
| --- | --- |
| Nix | The language these files are written in. Nix is also the tool that builds packages and systems from them. |
| nixpkgs | A large collection of packages, written in Nix. The files refer to it as `pkgs`. |
| NixOS | A Linux system that Nix builds from a set of configuration files. |
| Flake | A project with a `flake.nix` file at its root. It lists its inputs and outputs. |
| Input | Another flake that this one depends on, such as nixpkgs. The exact versions are pinned in `flake.lock`. |
| Module | A `.nix` file that sets options. NixOS merges all the modules into one system. |
| Option | A single setting, such as `services.printing.enable`. Dots separate the parts of the name. |
| Machine | A physical computer. Each machine has a folder under `modules/machines/`. |
| Platform | The operating system family for a machine: `nixos`, `darwin` (macOS), or `wsl`. Each is a folder under a machine. |
| Host | One named system built from a platform folder, such as the host `nixos`. |
| Feature | A set of settings that applies to every host. Features live in `modules/features/`. |
| Home Manager | A tool that manages one user's packages and dotfiles. It runs as part of the NixOS build. |
| `stateVersion` | The release a host was first installed with. Nix uses it to keep old defaults for existing data. Do not change it. |
| `lib.mkDefault` | Marks a value as a default. Another file can set a different value, and the other value wins. |
| Binary cache | A server with packages already built. Nix downloads from it instead of compiling. cache.nixos.org is the default. This repository also uses Numtide's cache for the AI coding agents. |
| Form factor | Whether a machine is a desktop or a laptop. Set with `machine.formFactor`. Laptops get battery controls in the bar and automatic power profiles. |
| niri | The Wayland compositor that draws and arranges windows. It places windows in columns on a strip that scrolls sideways. |
| Stylix | A tool that applies one color scheme and one set of fonts to many programs at once. |

## Layout

```
.
├── flake.nix                       Entry point. Declares the inputs and outputs.
├── flake.lock                      Exact versions of every input. Generated.
├── README.md                       This file.
├── AGENTS.md                       Instructions for coding agents.
├── .gitignore                      Keeps `nix build` result links out of git.
├── wallpapers/                     Wallpaper pictures any user can pick. Not loaded as modules.
│   ├── default.nix                 Maps each wallpaper's name to its picture.
│   ├── wallhaven-5yzd29.png        White cherry blossoms on black.
│   └── wallhaven-gwd987.jpg        A pink cherry blossom branch on black.
└── modules/
    ├── machines.nix                Finds machines, hosts, and users from folder names.
    ├── features/                   Settings for every host.
    │   ├── base.nix                Packages, flakes, binary caches, and time zone for all platforms.
    │   └── nixos/                  Settings for NixOS hosts only.
    │       ├── base.nix            NetworkManager and locale.
    │       └── form-factor.nix     The desktop or laptop setting, and laptop power profiles.
    └── machines/
        └── reatan-x7-00/           One physical computer.
            └── nixos/              Settings for NixOS hosts on this computer.
                ├── admin.nix       The login account details and the zsh login shell.
                ├── audio.nix       PipeWire sound.
                ├── bluetooth.nix   Bluetooth.
                ├── browsers.nix    Firefox.
                ├── desktop.nix     niri and the greetd login screen.
                ├── form-factor.nix Marks this machine as a desktop.
                ├── keyboard.nix    US keyboard layout.
                ├── power.nix       Power services and no sleep.
                ├── printing.nix    CUPS printing.
                └── hosts/
                    └── nixos/      The host named `nixos`.
                        ├── default.nix                 Boot settings.
                        ├── hardware-configuration.nix  Generated hardware settings. Do not edit.
                        └── users/
                            └── chrismg/                Home Manager settings for one user.
                                ├── default.nix     Packages.
                                ├── kitty.nix       Terminal.
                                ├── kitty/          The kitty tab bar.
                                ├── lock.nix        Lock screen.
                                ├── niri.nix        niri settings and key bindings.
                                ├── notifications.nix  SwayNotificationCenter.
                                ├── quickshell.nix  The bar.
                                ├── quickshell/     The bar's QML files.
                                ├── shell.nix       zsh and starship.
                                ├── theme.nix       Stylix colors and fonts.
                                ├── vicinae.nix     App launcher.
                                └── wallpaper.nix   Picks a wallpaper, drawn by wpaperd.
```

Each folder also has an `AGENTS.md` that describes its files.

## How the files combine

Nix does not read the folders in a fixed list. Instead, `modules/machines.nix` walks the folders and builds each host. It works like this.

1. Nix reads `flake.nix`, which loads `modules/machines.nix`.
2. `machines.nix` treats each folder in `modules/machines/` as a machine.
3. Inside a machine, each platform folder (`nixos`, `darwin`, or `wsl`) holds the hosts for that platform.
4. Inside a platform, each folder under `hosts/` is one host. The folder name is the host name.
5. For each host, Nix combines these files, in this order:
   1. Every `.nix` file in `modules/features/`, then the ones in `modules/features/nixos/` if the host runs NixOS.
   2. Every `.nix` file directly in the machine folder.
   3. Every `.nix` file directly in the platform folder.
   4. Every `.nix` file directly in the host folder.
   5. Home Manager, with one configuration for each folder under `users/`.
6. The result is one system. `nixos-rebuild --flake .#nixos` builds the host named `nixos`.

Files in the same list merge into one system. If two files set the same option to different values, Nix stops with a conflict error. Use `lib.mkDefault` for a value that another file may need to replace.

## Everyday tasks

These commands run from the root of the repository.

### Apply changes

```sh
sudo nixos-rebuild switch --flake .#nixos
```

This builds the system, activates it now, and makes it the default for the next boot.

### Try changes without a permanent boot entry

```sh
sudo nixos-rebuild test --flake .#nixos
```

This activates the new system now, but does not make it the default for the next boot. A reboot goes back to the previous system.

### Check the configuration without building it

```sh
nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
```

Nix evaluates the settings and prints the path of the build plan. It does not build anything, so it is much faster than a full rebuild. The first run downloads the inputs, so it can take a while.

### Update the pinned versions

```sh
nix flake update            # Update every input
nix flake update nixpkgs    # Update one input
```

This changes `flake.lock`. Rebuild afterward to use the new versions.

### Add a package for one user

Open `modules/machines/reatan-x7-00/nixos/hosts/nixos/users/chrismg/default.nix` and add the package to `home.packages`.

```nix
home.packages = [
  # ...existing packages...
  pkgs.htop
];
```

Search for package names at [search.nixos.org/packages](https://search.nixos.org/packages).

### Add a package for every user

Add the package to `environment.systemPackages` in `modules/features/base.nix`. That file covers every host, so the package goes everywhere.

### Add a setting for every host

Create a `.nix` file in `modules/features/`. For a setting that only NixOS supports, put the file in `modules/features/nixos/` instead.

### Add a new host

1. Create a folder under a platform, such as `modules/machines/reatan-x7-00/nixos/hosts/<name>/`. The folder name becomes the host name.
2. Add a `default.nix` with the boot settings for that computer.
3. On that computer, generate the hardware settings and save them as `hardware-configuration.nix` in the new folder:

   ```sh
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

4. Add a `users/<login>/default.nix` file for each user who needs Home Manager settings.
5. Run `git add` on the new files. Nix ignores files that git does not track. See the list below.
6. Build the host. The first build needs the command in [First build on a new computer](#first-build-on-a-new-computer), with `.#<name>` in place of `.#nixos`.

### First build on a new computer

The first time you build this configuration on a computer, run this instead of the usual command:

```sh
sudo nixos-rebuild switch --flake .#nixos \
  --option extra-substituters https://cache.numtide.com \
  --option extra-trusted-public-keys niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

`modules/features/base.nix` adds Numtide's binary cache, which holds the AI coding agents already built. That setting reaches `/etc/nix/nix.conf` only after the first build finishes, so the first build does not know about the cache yet. Without these two options, it compiles Codex from source, which can take half an hour.

- `extra-substituters` adds Numtide's cache for this one command, next to cache.nixos.org.
- `extra-trusted-public-keys` is Numtide's signing key. Nix uses it to check that each download really came from Numtide.

Both values match `modules/features/base.nix`, which copies them from the llm-agents flake. If you change them there, change them here too. After the first build, the usual `sudo nixos-rebuild switch --flake .#nixos` uses the cache by itself.

The options work because `sudo` runs the command as root, and Nix accepts cache settings from root. Run as a normal user, Nix ignores them.

### Add a user

Create a folder at `hosts/<host>/users/<login>/` with a `default.nix` file. The folder name must match the login name. The loader creates the login account automatically. Put account settings that affect the whole system, such as group membership, in the machine's `nixos/admin.nix`.

## Things that trip people up

- Nix ignores files that git does not track. Run `git add` on any new file before you build. Staging the file is enough.
- The host folder name sets the host name, the network name, and the flake output name. The three always match.
- An unknown folder name under a machine stops evaluation with an error. Only `nixos`, `darwin`, and `wsl` are allowed.
- If two hosts share a name in the same class, the first one wins and Nix drops the other one without a warning.
- `hardware-configuration.nix` is generated, and its header says not to edit it. Regenerate it when the hardware changes.
- `flake.lock` is generated. Use `nix flake update` instead of editing it by hand.
- Do not change a `stateVersion` value after the first install. Changing it can change defaults and break existing data.
- The `wsl` folder is built as NixOS, but no WSL support module is loaded. A WSL host needs its own WSL setup.
- The `darwin` code path exists, but no macOS machine is defined yet.
- A change to the login screen or the desktop stops the running desktop if you apply it with `switch`. Use `sudo nixos-rebuild boot --flake .#nixos` and then reboot.
- When Home Manager would replace a file it did not create, such as an existing `~/.zshrc`, it renames the old file to `<name>.hm-backup`. If that backup already exists, the older one is kept as `<name>.hm-backup.~1~`, then `~2~`, and so on. Delete old backups once you no longer need them.

## Learn more

- [Nix language basics](https://nix.dev/tutorials/nix-language) at nix.dev
- [NixOS manual](https://nixos.org/manual/nixos/stable/)
- [Option search](https://search.nixos.org/options) for every NixOS setting
- [Home Manager manual](https://nix-community.github.io/home-manager/)
