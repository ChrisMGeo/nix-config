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

  # Sets the clock to US Eastern time.
  time.timeZone = "America/New_York";

  # Packages installed system-wide, so every user can run them.
  # `with pkgs;` lets the list use plain names such as `vim` instead of `pkgs.vim`.
  environment.systemPackages = with pkgs; [
    vim # Terminal text editor
    git # Version control
  ];
}
