# Keyboard layout for NixOS hosts on the machine reatan-x7-00. The layout applies
# to the text console (the terminal before the desktop starts) and to the desktop.
#
# `_:` makes this file a function. `_` is a name for an argument the file does
# not use. Nix passes in a set of arguments, such as `pkgs` and `config`, and
# this file needs none of them.
_:

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
