# Settings for NixOS hosts only. Loaded because this file sits in features/nixos/.
# Files directly in features/ load for every platform. Files in features/nixos/
# load only for NixOS hosts, so an option that exists only on NixOS belongs here.
#
# `_:` makes this file a function. `_` is a name for an argument the file does
# not use. Nix passes in a set of arguments, such as `pkgs` and `config`, and
# this file needs none of them.
_:

{
  # Uses NetworkManager for networking. It handles Wi-Fi and wired connections,
  # and it creates the `networkmanager` group that admin.nix adds the user to.
  networking.networkmanager.enable = true;

  # Relaxes reverse-path filtering so incoming packets are accepted as long as
  # their source address is reachable through any network interface, rather than
  # requiring the exact same interface the packet arrived on. This prevents the
  # firewall from dropping asymmetrically routed traffic such as VPNs or
  # multi-interface setups.
  networking.firewall.checkReversePath = "loose";

  # Old generations and unused store paths are deleted by nh, once a week. See
  # nh.nix in this folder.

  # Replaces identical files in the store with one hard-linked copy each, so
  # duplicates take less space. It runs in the background after builds.
  nix.optimise.automatic = true;

  # The default language and text encoding. en_US.UTF-8 means English (United
  # States) with UTF-8 text.
  i18n.defaultLocale = "en_US.UTF-8";

  # Each LC_ setting controls one kind of formatting. All of them use US English here.
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8"; # Postal address format
    LC_IDENTIFICATION = "en_US.UTF-8"; # Metadata that describes the locale
    LC_MEASUREMENT = "en_US.UTF-8"; # Metric or imperial units
    LC_MONETARY = "en_US.UTF-8"; # Currency format
    LC_NAME = "en_US.UTF-8"; # How people's names are written
    LC_NUMERIC = "en_US.UTF-8"; # Decimal and thousands separators
    LC_PAPER = "en_US.UTF-8"; # Default paper size
    LC_TELEPHONE = "en_US.UTF-8"; # Phone number format
    LC_TIME = "en_US.UTF-8"; # Date and time format
  };
}
