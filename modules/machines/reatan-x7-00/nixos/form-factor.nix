# The form factor of the machine reatan-x7-00. Loaded for every NixOS host on
# this machine.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # This computer is a desktop. The option is declared in
  # modules/features/nixos/form-factor.nix. On a desktop the laptop charger rules
  # stay off.
  machine.formFactor = "desktop";
}
