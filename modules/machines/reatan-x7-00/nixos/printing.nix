# Printer support for NixOS hosts on the machine reatan-x7-00.
#
# `_:` makes this file a function. `_` is a name for an argument the file does
# not use. Nix passes in a set of arguments, such as `pkgs` and `config`, and
# this file needs none of them.
_:

{
  # Turns on CUPS, the standard printing system on Linux. It lets you add
  # printers and print from any app.
  services.printing.enable = true;
}
