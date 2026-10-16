# Shared sizes for the look of the desktop of the user `chrismg` on the host
# `nixos`. Loaded by machines.nix as a Home Manager module.
#
# Stylix sets colors, fonts, and opacity, but it has no setting for shapes
# such as rounded corners. This file adds one, so niri, the notifications, the
# launcher, and the Quickshell bar all read the same value instead of each
# typing its own.
#
# `{ lib, ... }:` makes this file a function. `lib` is the nixpkgs helper
# library.
{ lib, ... }:

{
  # `options` declares new settings that other modules can read. Here it adds
  # `look.cornerRadius`, read as `config.look.cornerRadius`.
  options.look = {
    # `mkOption` declares one setting. `type` makes Nix reject a value that
    # is not a whole number. `default` is the value used when no module sets
    # it, so changing this default changes the corners everywhere.
    cornerRadius = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 12;
      description = "How round the corners of windows and panels are, in pixels.";
    };
  };
}
