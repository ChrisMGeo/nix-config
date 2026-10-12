# Desktop notifications for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module.
#
# SwayNotificationCenter (swaync) shows notification popups. It also has a side
# panel that keeps past notifications and a do-not-disturb switch. Mod+N opens
# the panel. See niri.nix.
#
# The look is plain and dark: a dark panel, a thin outline, and rounded
# corners. The colors come from Stylix. See theme.nix.
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

  # swaync's own stylesheet. Setting `style` below replaces it, so the new style
  # loads it first and changes only what needs to change.
  defaultStyle = "${config.services.swaync.package}/etc/xdg/swaync/style.css";
in
{
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
          --cc-bg: ${hex.base00};
          --noti-bg: ${colors."base00-rgb-r"}, ${colors."base00-rgb-g"}, ${colors."base00-rgb-b"};
          --noti-bg-alpha: 1;
          --noti-bg-darker: ${hex.base01};
          --noti-bg-hover: ${hex.base01};
          --noti-bg-focus: ${rgba "base02" 0.6};
          --noti-border-color: ${rgba "base03" 0.55};
          --noti-close-bg: ${rgba "base05" 0.08};
          --noti-close-bg-hover: ${rgba "base05" 0.16};
          --text-color: ${hex.base05};
          --text-color-disabled: ${hex.base03};
          --bg-selected: ${hex.base02};
          --border-radius: 12px;
          --notification-icon-size: 40px;
          --notification-shadow: none;
          --font-size-summary: 14px;
          --font-size-body: 13px;
        }

        * {
          font-family: "${config.stylix.fonts.sansSerif.name}";
        }

        /* Space around each popup, 12 pixels from the right screen edge. */
        .floating-notifications .notification-row .notification-background {
          padding: 4px 12px 4px 12px;
        }

        /* One thin, dim outline. Stylix draws a second, bright one on the inner
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
          font-size: 12px;
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
          background: ${hex.base01};
        }

        /* The side panel and its widgets, with the same outline as the popups. */
        .control-center {
          border: 1px solid var(--noti-border-color);
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
