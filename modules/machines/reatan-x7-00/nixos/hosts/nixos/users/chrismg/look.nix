# Shared sizes for the look of the desktop of the user `chrismg` on the host
# `nixos`. Loaded by machines.nix as a Home Manager module.
#
# Stylix sets colors, fonts, and opacity, but it has no setting for shapes
# such as rounded corners or outline widths. This file adds them, so niri,
# the notifications, the launcher, and the Quickshell bar all read the same
# values instead of each typing its own.
#
# `{ lib, ... }:` makes this file a function. `lib` is the nixpkgs helper
# library.
{ lib, ... }:

{
  # `options` declares new settings that other modules can read. Here it adds
  # `look.cornerRadius` and the outline widths, read as
  # `config.look.cornerRadius` and so on.
  options.look = {
    # `mkOption` declares one setting. `type` makes Nix reject a value that
    # is not a whole number. `default` is the value used when no module sets
    # it, so changing this default changes the corners everywhere.
    cornerRadius = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 12;
      description = "How round the corners of windows and panels are, in pixels.";
    };

    # The outline around windows, the bar, and its cards.
    borderWidth = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 2;
      description = "How thick the outline around windows and the bar's panels is, in pixels.";
    };

    # The thinner outline around smaller things: the bar's drawers, menus,
    # sliders, and switches, the notification cards, and the launcher.
    thinBorderWidth = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 1;
      description = "How thick the outline around smaller panels and controls is, in pixels.";
    };
  };
}
