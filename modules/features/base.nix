# Settings for every host, on every platform (NixOS and darwin alike).
# Loaded automatically because this file sits directly in modules/features/.
#
# `{ pkgs, ... }:` makes this file a function. Nix passes in `pkgs`, the set of
# every package in nixpkgs. The `...` ignores any other arguments.
{ pkgs, ... }:

{
  # Allows packages whose license is not free software. Some drivers and apps need this.
  nixpkgs.config.allowUnfree = true;

  # Turns on the newer `nix` commands and flakes. Flakes are what let this
  # repository use flake.nix.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # A binary cache is a server with packages already built. Nix downloads from
  # it instead of compiling. Numtide's cache holds the AI coding agents from the
  # llm-agents input, so Codex does not compile from source on every update.
  # `extra-` adds to the default cache, cache.nixos.org, instead of replacing it.
  # The key proves that a download really came from Numtide. Both values come
  # from llm-agents' own flake.nix. The README's "First build on a new computer"
  # repeats them, so change both places together.
  nix.settings.extra-substituters = [ "https://cache.numtide.com" ];
  nix.settings.extra-trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];

  # Sets the clock to US Eastern time.
  time.timeZone = "America/New_York";

  # Packages installed system-wide, so every user can run them.
  # `with pkgs;` lets the list use plain names such as `vim` instead of `pkgs.vim`.
  environment.systemPackages = with pkgs; [
    vim # Terminal text editor
    git # Version control
  ];
}
