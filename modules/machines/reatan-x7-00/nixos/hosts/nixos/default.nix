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

  # Keeps only the 20 newest generations in the boot menu and on the small EFI
  # partition. Each one has its own kernel and initrd there. Older generations
  # are still in the store until nix.gc removes them.
  boot.loader.systemd-boot.configurationLimit = 20;

  # Uses the newest Linux kernel that nixpkgs provides. It can be newer than the
  # kernel that comes with the default NixOS release.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Loads amdgpu, the driver for the built-in AMD graphics, in the initrd, before
  # the rest of the system starts. Without this, the driver loads later, in no
  # fixed order with greetd. On one boot a faulty USB hub held up driver loading
  # for 35 seconds, so niri started the login screen on the plain firmware screen.
  # amdgpu then took over the screen and niri was left with a black one.
  hardware.amdgpu.initrd.enable = true;
}
