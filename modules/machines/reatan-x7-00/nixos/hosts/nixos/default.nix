# Boot settings for the host named `nixos`. Loaded only for this host, because the
# file sits in hosts/nixos/.
#
# `{ pkgs, ... }:` makes this file a function. Nix passes in `pkgs`, the set of
# every package in nixpkgs. The `...` ignores any other arguments.
{ pkgs, ... }:

{
  # Uses systemd-boot, a simple boot manager for computers that use UEFI firmware.
  boot.loader.systemd-boot.enable = true;

  # Lets NixOS write boot entries into the firmware's memory. systemd-boot needs
  # this to add the NixOS entry.
  boot.loader.efi.canTouchEfiVariables = true;

  # Uses the newest Linux kernel that nixpkgs provides. It can be newer than the
  # kernel that comes with the default NixOS release.
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
