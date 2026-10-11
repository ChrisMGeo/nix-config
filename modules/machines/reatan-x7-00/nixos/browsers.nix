# Web browsers for NixOS hosts on the machine reatan-x7-00.
# Brave is not here. It is installed for one user in
# hosts/nixos/users/chrismg/default.nix.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # Installs Firefox for every user on the machine.
  programs.firefox.enable = true;
}
