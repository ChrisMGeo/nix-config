# The form factor of the machine reatan-x7-00. Loaded for every NixOS host on
# this machine.
#
# `_:` makes this file a function. `_` is a name for an argument the file does
# not use. Nix passes in a set of arguments, such as `pkgs` and `config`, and
# this file needs none of them.
_:

{
  # This computer is a desktop. The option is declared in
  # modules/features/nixos/form-factor.nix. On a desktop the laptop charger rules
  # stay off.
  machine.formFactor = "desktop";
}
