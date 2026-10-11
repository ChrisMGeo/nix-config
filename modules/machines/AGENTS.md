# machines

One folder per physical computer. The folder name is the machine name. The loader uses it only to find the folder.

## Expected layout

```
machines/
└── <machine>/                   .nix files here load for every host on this machine.
    └── <platform>/              nixos, darwin, or wsl. .nix files here load for every host on this platform.
        ├── *.nix
        └── hosts/
            └── <host>/          One host. The folder name is the host name.
                ├── *.nix        Load for this host only.
                └── users/
                    └── <user>/  Home Manager modules for one user.
```

## Subdirectories

- [reatan-x7-00/](reatan-x7-00/AGENTS.md): the only machine defined today.

## Rules

- Platform folders must be named `nixos`, `darwin`, or `wsl`. `wsl` builds as NixOS, but no WSL support module loads for it.
- A `.nix` file directly in a machine folder loads for every platform on that machine. None exist today.
- Within one class, host names must be unique. If two hosts share a name, the first one wins and the second is dropped without a warning.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
