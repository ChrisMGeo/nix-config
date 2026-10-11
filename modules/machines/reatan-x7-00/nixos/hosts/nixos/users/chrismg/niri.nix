# The niri settings file, ~/.config/niri/config.kdl, for the user `chrismg` on the
# host `nixos`. Loaded by machines.nix as a Home Manager module.
#
# niri reads a file in the KDL format. This file describes the settings as a Nix
# set, and Home Manager's `toKDL` turns the set into KDL text. niri reloads the
# file by itself when it changes. Run `niri validate` to check the result.
#
# This file replaces niri's built-in default settings completely, so every key
# binding you want must be listed under `binds`.
#
# `{ config, lib, osConfig, pkgs, ... }:` makes this file a function. `config` is
# this user's final Home Manager settings. `lib` is the nixpkgs helper library.
# `osConfig` is the whole system's final settings, which Home Manager passes in.
# `pkgs` is the package set.
{ config, lib, osConfig, pkgs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # Full paths to the programs that the key bindings start. `getExe` returns the
  # path of a package's main program.
  vicinae = lib.getExe config.programs.vicinae.package;
  kitty = lib.getExe config.programs.kitty.package;
  # `getExe'` returns the path of a named program inside a package, for packages
  # that hold more than one program.
  swaync-client = lib.getExe' config.services.swaync.package "swaync-client";

  # Changes the volume of the default speaker or microphone. Part of WirePlumber,
  # which PipeWire uses. See audio.nix.
  wpctl = "${osConfig.services.pipewire.wireplumber.package}/bin/wpctl";
  # Sends play, pause, next, and previous to the media player that is playing.
  playerctl = lib.getExe pkgs.playerctl;
  # Changes a laptop screen's brightness.
  brightnessctl = lib.getExe pkgs.brightnessctl;

  # A key binding that also works while the screen is locked, such as volume.
  # `_props` becomes a KDL property: `allow-when-locked=true`.
  whenLocked = command: {
    _props.allow-when-locked = true;
    spawn = command;
  };

  # Mod+1 to Mod+9 jump to that workspace on the focused monitor. Mod+Shift+1
  # to Mod+Shift+9 move the focused column there. `genList` makes the list 1 to
  # 9, `concatMap` turns each number into two bindings, and `listToAttrs` turns
  # the list of { name; value; } pairs into one set.
  workspaceBinds = lib.listToAttrs (lib.concatMap (n: [
    { name = "Mod+${toString n}"; value."focus-workspace" = n; }
    { name = "Mod+Shift+${toString n}"; value."move-column-to-workspace" = n; }
  ]) (lib.genList (i: i + 1) 9));

  # Brightness keys, only on laptops. A desktop monitor has no backlight that
  # brightnessctl can reach. `optionalAttrs cond set` returns `set` when `cond`
  # is true and an empty set otherwise.
  laptopBinds = lib.optionalAttrs (osConfig.machine.formFactor == "laptop") {
    "XF86MonBrightnessUp" = whenLocked [ brightnessctl "set" "5%+" ];
    "XF86MonBrightnessDown" = whenLocked [ brightnessctl "set" "5%-" ];
  };

  # The Stylix colors as "#rrggbb" strings, such as colors.base03.
  colors = config.lib.stylix.colors.withHashtag;

  niriConfig = {
    # Use the same keyboard layout as the rest of the system, set in keyboard.nix.
    input.keyboard.xkb.layout = osConfig.services.xserver.xkb.layout;

    # Rounds the corners of every window, and cuts the window's content to match.
    "window-rule" = {
      "geometry-corner-radius" = 12;
      "clip-to-geometry" = true;
    };

    layout = {
      # Space between windows, and between windows and the screen edge, in pixels.
      gaps = 16;
      # A thin outline around the focused window of each monitor. The monitor
      # that has the keyboard uses the active color, a mid gray. The others use
      # the inactive color, a darker gray, so you can see which monitor typing
      # goes to.
      "focus-ring" = {
        width = 1;
        "active-color" = colors.base03;
        "inactive-color" = colors.base02;
      };
    };

    # niri shows a list of important key bindings when it starts, unless this is
    # set. Mod+Shift+Slash still shows it.
    "hotkey-overlay"."skip-at-startup" = { };

    # Key bindings. Mod is the Super (Windows) key. `{ }` means the action takes
    # no arguments. A list means a program and its arguments. `//` merges two
    # sets, so the generated workspace and laptop bindings join the ones below.
    binds = workspaceBinds // laptopBinds // {
      # Programs.
      "Mod+Return".spawn = [ kitty ];
      "Mod+D".spawn = [ vicinae "toggle" ];
      # Opens or closes the notification panel. See notifications.nix.
      "Mod+N".spawn = [ swaync-client "-t" "-sw" ];

      # Windows.
      "Mod+Q"."close-window" = { };
      "Mod+F"."maximize-column" = { };
      "Mod+Shift+F"."fullscreen-window" = { };
      "Mod+V"."toggle-window-floating" = { };
      # Centers the focused column on the screen.
      "Mod+C"."center-column" = { };

      # Move the focus. H and L move between columns. J and K move between the
      # windows stacked in one column.
      "Mod+H"."focus-column-left" = { };
      "Mod+L"."focus-column-right" = { };
      "Mod+J"."focus-window-down" = { };
      "Mod+K"."focus-window-up" = { };

      # Move the focused column or window. Same keys, plus Shift.
      "Mod+Shift+H"."move-column-left" = { };
      "Mod+Shift+L"."move-column-right" = { };
      "Mod+Shift+J"."move-window-down" = { };
      "Mod+Shift+K"."move-window-up" = { };

      # Put windows in one column, or take them out. Comma pulls the window from
      # the column to the right into the focused column. Period pushes the bottom
      # window out into its own column. The brackets do either, toward the left or
      # the right.
      "Mod+Comma"."consume-window-into-column" = { };
      "Mod+Period"."expel-window-from-column" = { };
      "Mod+BracketLeft"."consume-or-expel-window-left" = { };
      "Mod+BracketRight"."consume-or-expel-window-right" = { };

      # Column width. R cycles through preset widths. Minus and Equal shrink and grow.
      "Mod+R"."switch-preset-column-width" = { };
      "Mod+Minus"."set-column-width" = "-10%";
      "Mod+Equal"."set-column-width" = "+10%";

      # Workspaces are stacked vertically. U and I move between them.
      "Mod+U"."focus-workspace-down" = { };
      "Mod+I"."focus-workspace-up" = { };
      "Mod+Shift+U"."move-column-to-workspace-down" = { };
      "Mod+Shift+I"."move-column-to-workspace-up" = { };

      # Volume and media keys. They work on the lock screen too. 5% steps, with
      # the volume capped at 100%.
      "XF86AudioRaiseVolume" = whenLocked [ wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" "-l" "1.0" ];
      "XF86AudioLowerVolume" = whenLocked [ wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
      "XF86AudioMute" = whenLocked [ wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
      "XF86AudioMicMute" = whenLocked [ wpctl "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
      "XF86AudioPlay" = whenLocked [ playerctl "play-pause" ];
      "XF86AudioPause" = whenLocked [ playerctl "play-pause" ];
      "XF86AudioNext" = whenLocked [ playerctl "next" ];
      "XF86AudioPrev" = whenLocked [ playerctl "previous" ];

      # Shows every workspace zoomed out.
      "Mod+O"."toggle-overview" = { };

      # Screenshots. Print picks an area, Ctrl+Print takes the screen, and
      # Alt+Print takes the focused window. niri copies the result to the
      # clipboard and saves it in ~/Pictures/Screenshots.
      "Print".screenshot = { };
      "Ctrl+Print"."screenshot-screen" = { };
      "Alt+Print"."screenshot-window" = { };

      # Shows a list of the key bindings.
      "Mod+Shift+Slash"."show-hotkey-overlay" = { };

      # Leaves niri and returns to the login screen. niri asks first.
      "Mod+Shift+E".quit = { };
    };
  };
in
{
  # `xdg.configFile."<path>"` writes a file under ~/.config. `toKDL` converts the
  # Nix set above to KDL text.
  xdg.configFile."niri/config.kdl".text = lib.hm.generators.toKDL { } niriConfig;
}
