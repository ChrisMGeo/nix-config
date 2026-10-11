# Printer support for NixOS hosts on the machine reatan-x7-00.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # Turns on CUPS, the standard printing system on Linux. It lets you add
  # printers and print from any app.
  services.printing.enable = true;
}
