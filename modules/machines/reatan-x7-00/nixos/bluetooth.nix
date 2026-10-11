# Bluetooth for NixOS hosts on the machine reatan-x7-00.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # Turns on the Bluetooth adapter and BlueZ, the Linux Bluetooth service.
  # Programs such as the Quickshell bar talk to BlueZ to show the adapter and
  # switch it on and off.
  hardware.bluetooth.enable = true;
}
