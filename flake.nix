# The entry point of this repository. Nix reads this file first when you run a
# command such as `sudo nixos-rebuild switch --flake .#nixos`.
#
# A flake has two parts.
#   inputs   Other projects this one depends on, such as nixpkgs and Home Manager.
#            Their exact versions are recorded in flake.lock.
#   outputs  What this flake produces, such as the system configurations.
#
# This file only declares the inputs and hands the outputs to modules/machines.nix,
# which does the real work.
{
  # A one-line description, shown by `nix flake metadata`.
  description = "Chris' NixOS configuration";

  inputs = {
    # The stable package set for NixOS 26.05. Most packages come from here.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # The rolling package set. Used for individual packages that are newer here
    # than in the stable set. See users/chrismg/default.nix for an example.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Packages for AI coding agents (Codex, OpenCode, and Claude Code), from Numtide.
    llm-agents.url = "github:numtide/llm-agents.nix";

    home-manager = {
      # Home Manager manages one user's packages and dotfiles, separately from the system.
      url = "github:nix-community/home-manager/release-26.05";
      # Reuse this flake's nixpkgs instead of a second copy. The system then has one
      # nixpkgs, which means less to download and build.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      # Stylix applies one color scheme and one set of fonts to many programs at
      # once, such as kitty, GTK and Qt apps, and the notification center.
      url = "github:nix-community/stylix/release-26.05";
      # Same as Home Manager above: share one nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      # nix-darwin is the macOS version of NixOS. No macOS machine is defined yet,
      # but the module code is ready for one.
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      # Same as Home Manager above: share one nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae-extensions = {
      # The community extensions for the Vicinae launcher. The repository is a
      # flake with one package per extension. users/chrismg/vicinae.nix picks
      # the extensions to install.
      url = "github:vicinaehq/extensions";
      # Builds the extensions with nixpkgs-unstable, the same set the Vicinae
      # launcher itself comes from, instead of a separate copy of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # flake-parts splits a flake's outputs into modules. See `imports` below.
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  # `outputs` is a function. Nix calls it with every input and uses the result as
  # the flake's outputs.
  #
  # `inputs@{ flake-parts, ... }` does two things. `inputs@` keeps the whole set
  # under the name `inputs`. `{ flake-parts, ... }` pulls out the `flake-parts`
  # input by name. The `...` means the other inputs are ignored here.
  outputs =
    inputs@{ flake-parts, ... }:
    # `mkFlake` turns the module list below into the flake's outputs.
    # `inherit inputs` is shorthand for `inputs = inputs;`. It passes every input
    # to the modules.
    flake-parts.lib.mkFlake { inherit inputs; } {
      # The CPU and OS types this flake knows about. The machine configurations pick
      # their own platform, so nothing in this repository uses this list yet.
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      # Modules to load. This one finds every machine from the folder layout and
      # sets the nixosConfigurations and darwinConfigurations outputs.
      imports = [ ./modules/machines.nix ];
    };
}
