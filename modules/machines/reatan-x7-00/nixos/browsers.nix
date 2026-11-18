# Web browsers for NixOS hosts on the machine reatan-x7-00.
# Brave is not here. It is installed for one user in
# hosts/nixos/users/chrismg/default.nix.
#
# `_:` makes this file a function. `_` is a name for an argument the file does
# not use. Nix passes in a set of arguments, such as `pkgs` and `config`, and
# this file needs none of them.
_:

{
  # Installs Firefox for every user on the machine.
  programs.firefox.enable = true;
}
