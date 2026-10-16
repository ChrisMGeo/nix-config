# Desktop notifications for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module.
#
# SwayNotificationCenter (swaync) shows notification popups. It also has a side
# panel that keeps past notifications and a do-not-disturb switch. Mod+N opens
# the panel. See niri.nix.
#
# The look is plain and dark: a see-through black panel, a thin gray outline,
# and rounded corners. The colors and the opacity come from Stylix. See
# theme.nix.
#
# `{ config, lib, ... }:` makes this file a function. `config` is this user's
# final Home Manager settings. `lib` is the nixpkgs helper library.
{ config, lib, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The Stylix colors. `withHashtag` gives "#rrggbb" strings.
  colors = config.lib.stylix.colors;
  hex = colors.withHashtag;

  # Turns a color slot, such as "base03", and an opacity into a CSS rgba() value.
  # Stylix also provides each color as three numbers, such as "base03-rgb-r".
  rgba = slot: alpha:
    "rgba(${colors."${slot}-rgb-r"}, ${colors."${slot}-rgb-g"}, ${colors."${slot}-rgb-b"}, ${toString alpha})";

  # How opaque the popups and the side panel are, from 0 (invisible) to 1
  # (solid). It is stylix.opacity.popups from theme.nix, the same as the bar
  # and the launcher.
  opacity = config.stylix.opacity.popups;

  # The corner radius of the popups and the side panel, in pixels.
  radius = 12;

  # The size of the message text, in points. It is stylix.fonts.sizes.popups
  # from theme.nix, the same as the launcher. The title is one point larger
  # and the time one point smaller.
  fontSize = config.stylix.fonts.sizes.popups;

  # swaync's own stylesheet. Setting `style` below replaces it, so the new style
  # loads it first and changes only what needs to change.
  defaultStyle = "${config.services.swaync.package}/etc/xdg/swaync/style.css";
in
{
  # Shares the corner radius with niri.nix, which rounds the blur behind the
  # side panel to match. `lib` is a Home Manager setting where modules can put
  # values for other modules to read, as `config.lib.swaync.radius`.
  lib.swaync.radius = radius;

  services.swaync = {
    # Runs swaync as a systemd user service. It starts with the niri session,
    # because niri-session starts the graphical session target that the service
    # waits for.
    enable = true;

    # Written to ~/.config/swaync/config.json.
    settings = {
      # Popups appear in the top right corner, above every window.
      positionX = "right";
      positionY = "top";
      layer = "overlay";

      # Narrower than the default 500 pixels, so popups do not cover much text.
      notification-window-width = 400;
      # App icons in pixels. The default shows them at full size.
      notification-icon-size = 40;

      # Seconds before a popup hides by itself. Low priority popups go sooner.
      # Critical ones stay until you close them.
      timeout = 6;
      timeout-low = 4;
      timeout-critical = 0;

      # The side panel. It keeps a 12 pixel margin from the screen edges, the
      # same as the popups.
      control-center-width = 400;
      control-center-margin-top = 8;
      control-center-margin-right = 12;
      control-center-margin-bottom = 12;
      fit-to-screen = true;

      # Faster slide-in and slide-out animations, in milliseconds.
      transition-time = 150;
    };

    # Written to ~/.config/swaync/style.css. Stylix adds its own color rules to
    # this option. `mkMerge` combines several values into one. `mkBefore` puts a
    # value first, and `mkAfter` puts it last, so later rules win over Stylix.
    style = lib.mkMerge [
      # CSS requires @import before any other rule.
      (lib.mkBefore ''
        @import url("file://${defaultStyle}");
      '')

      (lib.mkAfter ''
        /* Values that swaync's own stylesheet reads. */
        :root {
          --cc-bg: ${rgba "base00" opacity};
          --noti-bg: ${colors."base00-rgb-r"}, ${colors."base00-rgb-g"}, ${colors."base00-rgb-b"};
          --noti-bg-alpha: ${toString opacity};
          --noti-bg-darker: ${hex.base01};
          --noti-bg-hover: ${rgba "base01" opacity};
          --noti-bg-focus: ${rgba "base02" 0.6};
          --noti-border-color: ${rgba "base03" 0.55};
          --noti-close-bg: ${rgba "base05" 0.08};
          --noti-close-bg-hover: ${rgba "base05" 0.16};
          --text-color: ${hex.base05};
          --text-color-disabled: ${hex.base03};
          --bg-selected: ${hex.base02};
          --border-radius: ${toString radius}px;
          --notification-icon-size: 40px;
          --notification-shadow: none;
          --font-size-summary: ${toString (fontSize + 1)}pt;
          --font-size-body: ${toString fontSize}pt;
        }

        /* Space around each popup, 12 pixels from the right screen edge. */
        .floating-notifications .notification-row .notification-background {
          padding: 4px 12px 4px 12px;
        }

        /* One thin gray outline. Stylix draws a second, bright one on the inner
           box, which this removes. */
        .notification-row .notification-background .notification {
          border: 1px solid var(--noti-border-color);
          background: rgba(var(--noti-bg), var(--noti-bg-alpha));
        }

        .notification-row .notification-background .notification .notification-default-action .notification-content {
          border: none;
          background: transparent;
          padding: 10px 12px;
        }

        /* swaync paints a square box behind the focused group or row in the side
           panel. Remove it and show focus on the card's rounded outline instead. */
        .notification-group,
        .notification-group:focus,
        .notification-row:focus {
          background: transparent;
          outline: none;
          box-shadow: none;
        }

        .notification-group:focus .notification-row .notification,
        .notification-row:focus .notification {
          border-color: ${rgba "base05" 0.6};
        }

        /* Critical popups get a brighter outline instead of a color. */
        .notification-row .notification-background .notification.critical {
          border-color: ${rgba "base05" 0.75};
        }

        .notification-row .notification-background .notification .notification-default-action .notification-content .image {
          border-radius: 10px;
          margin: 2px 12px 2px 0;
        }

        /* The title: bright and bold. */
        .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .summary {
          color: ${hex.base07};
          font-weight: bold;
        }

        /* The time: small and dim, so it does not compete with the title. */
        .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .time {
          color: ${hex.base03};
          font-size: ${toString (fontSize - 1)}pt;
          font-weight: normal;
        }

        /* The message: a little dimmer than the title. */
        .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .body {
          color: ${hex.base04};
        }

        /* A thin rounded progress bar, without Stylix's bright outline. */
        .notification-row .notification-background .notification .notification-default-action .notification-content progressbar {
          margin-top: 8px;
        }

        .notification progressbar,
        .notification progressbar trough,
        .notification progressbar progress {
          border: none;
          border-radius: 3px;
          min-height: 4px;
        }

        .notification progressbar trough {
          background: ${hex.base02};
        }

        .notification progressbar progress {
          background: ${hex.base05};
        }

        /* The round close button in the corner. */
        .close-button {
          background: var(--noti-close-bg);
          color: ${hex.base05};
        }

        .close-button:hover {
          background: var(--noti-close-bg-hover);
          color: ${hex.base07};
        }

        /* Action buttons under a popup. */
        .notification-action {
          background: transparent;
          color: ${hex.base05};
          border: none;
          border-top: 1px solid ${rgba "base03" 0.3};
        }

        .notification-action:hover {
          background: var(--noti-bg-hover);
        }

        /* The side panel and its widgets, with the same outline as the popups.
           Stylix paints the panel solid black, which would hide the
           see-through --cc-bg, so the background is set again here. */
        .control-center {
          background: var(--cc-bg);
          border: 1px solid var(--noti-border-color);
        }

        /* Stylix paints a solid black box around each card in the side panel,
           larger than the card. Remove it, so only the card itself shows. */
        .control-center .notification-row .notification-background,
        .control-center .notification-row .notification-background:hover {
          background: transparent;
        }

        /* Cards in the side panel have no background of their own, so they
           show the panel's see-through black and blur. The second selector
           covers cards in a collapsed group, which swaync and Stylix paint
           solid. */
        .control-center .notification-row .notification-background .notification,
        .control-center .notification-group.collapsed .notification-row .notification {
          background: transparent;
        }

        /* A collapsed group draws up to two more cards under the newest one,
           each a little narrower and 8 pixels lower, so their bottom edges
           peek out below it. swaync already hides their text. They keep only
           the bottom outline, so nothing of them shows through the
           see-through card on top. The second selector keeps it that way
           while the pointer is over the group, where swaync would paint them. */
        .control-center .notification-group.collapsed .notification-row:not(:last-child) .notification,
        .control-center .notification-group.collapsed:hover .notification-row:not(:last-child) .notification {
          background: transparent;
          border-color: transparent transparent var(--noti-border-color) transparent;
        }

        .widget-title > button,
        .widget-dnd > switch,
        .widget-mpris .widget-mpris-player,
        .widget-mpris .widget-mpris-player > box > button {
          border: 1px solid var(--noti-border-color);
        }

        .widget-dnd > switch:checked {
          background: ${hex.base04};
        }
      '')
    ];
  };
}
