# Shared sizes for the look of the desktop of the user `chrismg` on the host
# `nixos`. Loaded by machines.nix as a Home Manager module.
#
# Stylix sets colors, fonts, and opacity, but it has no setting for shapes
# and spacing, such as rounded corners, outline width, margins, and the glow
# around windows and panels. This file adds them, so niri, the notifications,
# the launcher, and the Quickshell bar all read the same values instead of
# each typing its own.
#
# `{ lib, ... }:` makes this file a function. `lib` is the nixpkgs helper
# library.
{ lib, ... }:

{
  # `options` declares new settings that other modules can read. Here it adds
  # `look.cornerRadius`, the outline width, the margins, and the glow, read as
  # `config.look.cornerRadius` and so on.
  options.look = {
    # `mkOption` declares one setting. `type` makes Nix reject a value that
    # is not a whole number. `default` is the value used when no module sets
    # it, so changing this default changes the corners everywhere.
    # Windows, panels, popups, and cards have square corners. This radius is
    # for the smaller things inside them, such as buttons, list rows, the
    # workspace buttons, and the notification pictures, which use it or a few
    # pixels less.
    cornerRadius = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 12;
      description = "How round the corners of buttons, rows, and other parts inside windows and panels are, in pixels. Windows and panels themselves are square.";
    };

    # The outline around small controls in the bar: switches, slider knobs,
    # and text boxes. Windows, panels, and cards have no outline.
    borderWidth = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 1;
      description = "How thick the outline around small controls in the bar is, in pixels.";
    };

    # The space niri leaves between windows, and between windows and the
    # screen edges.
    windowGap = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 16;
      description = "Space between windows, and between windows and the screen edges, in pixels.";
    };

    # The soft light glow around the focused niri window and around the
    # Quickshell panels. niri.nix and quickshell/PanelGlow.qml both read
    # these, so the two glows look the same.
    # Softness is how far the glow fades out. niri blurs with a Gaussian
    # curve whose width, called sigma, is half the softness, and the glow
    # reaches about three sigma past its edge.
    glowSoftness = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 12;
      description = "How far the glow around the focused window and the panels fades out, in pixels.";
    };

    # How far the glow's starting edge sits outside the window. A blurred
    # rectangle is fainter at its corners than along its sides, because both
    # edges fade there at once, so the glow looks rounded. Moving the edge out
    # by half the softness makes the glow almost full strength at the window's
    # corners, so they look square.
    glowSpread = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 6;
      description = "How far outside the window or panel the glow starts to fade, in pixels. Half of glowSoftness keeps the corners square.";
    };

    # How strong the glow is at its brightest, from 0 (clear) to 255 (solid).
    # 40 is about a sixth.
    glowAlpha = lib.mkOption {
      type = lib.types.ints.between 0 255;
      default = 40;
      description = "How opaque the glow is at its brightest, from 0 to 255.";
    };

    # The space between the screen's left, right, and bottom edges and the
    # bar, its drawers, the notification side panel, and the popups.
    screenMargin = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 12;
      description = "Space between the screen edges and the bar, its drawers, and the notifications, in pixels.";
    };

    # The space above the bar and the notification side panel, so their tops
    # line up.
    topMargin = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 8;
      description = "Space between the top screen edge and the bar and the notification side panel, in pixels.";
    };
  };
}
