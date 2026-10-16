# Home Manager settings for the user `chrismg` on the host `nixos`.
#
# Home Manager manages one user's packages and dotfiles. It does not change
# system-wide settings. Each .nix file in this folder is a Home Manager module,
# and machines.nix loads it for this user.
#
# `{ inputs, pkgs, ... }:` makes this file a function. `inputs` is the flake's
# inputs. machines.nix passes them to Home Manager. `pkgs` is the package set.
{ inputs, pkgs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The platform of this machine, such as "x86_64-linux". Used to pick the matching
  # package sets below.
  system = pkgs.stdenv.hostPlatform.system;

  # Packages from the llm-agents flake, built for this platform.
  # `.packages.${system}` picks the package set for `system`.
  agents = inputs.llm-agents.packages.${system};

  # The nixpkgs-unstable package set, which is rolling and often has newer versions.
  # `legacyPackages` is the name nixpkgs uses for its package set in flakes.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in

{
  # Packages installed for this user only. Add a package by adding its name to
  # this list. Items in a Nix list are separated by spaces, not commas.
  home.packages = [
    # AI coding agents, from the llm-agents flake.
    agents.codex
    agents.opencode
    agents.claude-code

    # Web browser, from the stable nixpkgs set (`pkgs`).
    pkgs.brave

    # Prints system details, such as the OS, kernel, and memory, next to a logo.
    # From the stable nixpkgs set.
    pkgs.fastfetch

    # Vesktop, a Discord client with the Vencord plugins built in. Unlike the
    # official client, it can share the screen with audio under Wayland.
    # From the stable nixpkgs set.
    pkgs.vesktop

    # Zed code editor, from nixpkgs-unstable.
    unstable.zed-editor
  ];
}
