# Keyboard layout for NixOS hosts on the machine reatan-x7-00. The layout applies
# to the text console (the terminal before the desktop starts) and to the desktop.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # The layout for the text console. "us" is the standard US English layout.
  console.keyMap = "us";

  # The layout for the graphical desktop. `xkb` is the system that handles
  # keyboard layouts.
  services.xserver.xkb = {
    # "us" is the standard US English layout.
    layout = "us";

    # A variant tweaks the layout, such as Dvorak. An empty string means no variant.
    variant = "";
  };
}
