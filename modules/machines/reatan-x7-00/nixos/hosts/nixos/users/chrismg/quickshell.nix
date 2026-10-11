# The Quickshell bar for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module.
#
# Quickshell draws desktop panels from QML files. The QML files live in the
# quickshell/ folder next to this file. This file copies them to
# ~/.config/quickshell/chrismg and adds a generated Theme.qml with the Stylix
# colors and the paths to cava, the audio visualizer, and its settings file,
# quickshell/cava.conf. The bar runs as a systemd user service from login.
#
# The bar works on any computer. It shows the battery and power profile controls
# only when `machine.formFactor` is "laptop". See
# modules/features/nixos/form-factor.nix.
#
# `{ config, osConfig, pkgs, ... }:` makes this file a function. `config` is this
# user's final Home Manager settings. `osConfig` is the whole system's final
# settings. `pkgs` is the package set.
{ config, osConfig, pkgs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The Stylix colors as "#rrggbb" strings.
  colors = config.lib.stylix.colors.withHashtag;
  # Turns a Stylix color slot, such as "base00", into a quoted QML string.
  # `builtins.toJSON` adds the quotes.
  color = slot: builtins.toJSON colors.${slot};

  # How many bars the audio visualizer draws. cava must print exactly this many
  # numbers per frame, so both cava.conf and Theme.qml take it from here.
  spectrumBars = 48;

  # quickshell/cava.conf with `@bars@` replaced by the number above, copied into
  # the Nix store. `./quickshell/cava.conf` is a path relative to this file.
  # `replaceVars` fails the build if the file has a placeholder that is not
  # listed here. `toString` turns the number into text.
  cavaConfig = pkgs.replaceVars ./quickshell/cava.conf {
    bars = toString spectrumBars;
  };

  # Prints CPU, memory, and GPU use as one line of numbers. The bar runs it every
  # few seconds and computes percentages from the change between two readings.
  systemUsageReader = pkgs.writeShellScript "quickshell-system-usage" ''
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle_total=$((idle + iowait))

    mem_total=0
    mem_available=0
    while read -r key value _; do
      case "$key" in
        MemTotal:) mem_total=$value ;;
        MemAvailable:) mem_available=$value ;;
      esac
    done < /proc/meminfo

    mem_used=$((mem_total - mem_available))

    gpu=0
    gpu_available=0
    vram_used=0
    vram_total=0
    for device in /sys/class/drm/card*/device; do
      if [ -r "$device/gpu_busy_percent" ]; then
        read -r gpu < "$device/gpu_busy_percent"
        gpu_available=1
        # Read both metrics from the same GPU. VRAM sysfs values are bytes.
        if [ -r "$device/mem_info_vram_used" ] && [ -r "$device/mem_info_vram_total" ]; then
          read -r vram_used < "$device/mem_info_vram_used"
          read -r vram_total < "$device/mem_info_vram_total"
        fi
        break
      fi
    done

    printf '%s %s %s %s %s %s %s %s\n' \
      "$total" "$idle_total" "$((mem_used * 1024))" "$((mem_total * 1024))" \
      "$gpu" "$gpu_available" "$vram_used" "$vram_total"
  '';

  # Exits with 0 when power-profiles-daemon is running. The bar uses it to decide
  # whether to show the profile buttons.
  powerProfilesProbe = pkgs.writeShellScript "quickshell-power-profiles-available" ''
    ${pkgs.systemd}/bin/busctl --system --quiet status net.hadess.PowerProfiles \
      >/dev/null 2>&1
  '';

  # Theme.qml holds every color, size, and font that the other QML files use.
  # It is generated here so the colors match Stylix. `${...}` inserts a Nix value
  # into the text.
  generatedTheme = pkgs.writeText "quickshell-theme.qml" ''
    pragma Singleton

    import QtQuick

    QtObject {
        // Change this one value to switch typography throughout the shell.
        property string fontFamily: ${builtins.toJSON config.stylix.fonts.sansSerif.name}
        property string iconFontFamily: "Font Awesome 7 Free Solid"
        property string brandIconFontFamily: "Font Awesome 7 Brands"
        property string systemUsageCommand: "${systemUsageReader}"
        property string powerProfilesCommand: "${powerProfilesProbe}"
        // Exact store paths, so the visualizer does not depend on any profile.
        property string cavaCommand: "${pkgs.cava}/bin/cava"
        property string cavaConfig: "${cavaConfig}"
        // True on laptops. Desktops hide the battery and power profile controls.
        property bool showPower: ${if osConfig.machine.formFactor == "laptop" then "true" else "false"}
        property real uiScale: 1.15

        function scaled(value) {
            return Math.round(value * uiScale);
        }

        // Stylix Base16 colors.
        property color panel: ${color "base00"}
        property color panelOverlay: Qt.rgba(panel.r, panel.g, panel.b, 0.65)
        property color surface: ${color "base01"}
        property color surfaceRaised: ${color "base02"}
        property color surfaceHover: ${color "base02"}
        property color outline: ${color "base03"}
        property color outlineTranslucent: Qt.rgba(outline.r, outline.g, outline.b, 0.55)
        property color outlineFaint: Qt.rgba(outline.r, outline.g, outline.b, 0.22)
        property color subtleButton: Qt.rgba(text.r, text.g, text.b, 0.06)
        property color text: ${color "base05"}
        property color textMuted: ${color "base04"}
        property color accent: ${color "base0D"}
        property color accentText: ${color "base00"}
        property color positive: ${color "base0B"}
        property color warning: ${color "base0A"}
        property color destructive: ${color "base08"}
        property color magenta: ${color "base0E"}
        property color cyan: ${color "base0C"}

        property int outlineWidth: 2
        property int compactOutlineWidth: 1
        property int outerMargin: 12
        property int barTopGap: 8
        property int barBottomGap: 8
        property int gap: 8
        property int radius: 12
        property int barHeight: scaled(46)
        property int drawerWidth: scaled(352)
        property int textSize: scaled(13)
        property int topBarIconSize: scaled(11)
        property int spectrumBars: ${toString spectrumBars}
        property int mediaSpectrumBars: 8

        // Clock placement as a fraction of the screen's usable width and height.
        property real clockLeft: 0.11
        property real clockTop: 0.20
        property real clockWidth: scaled(308)
        property real clockHeight: scaled(180)
        property real mediaLeft: 0.58
        property real mediaTop: 0.66
        property real mediaWidth: scaled(420)
        property real mediaHeight: scaled(292)
    }
  '';

  # One folder with the QML files from quickshell/ plus the generated Theme.qml.
  # `runCommandLocal` runs a small shell script that builds the folder.
  quickshellConfig = pkgs.runCommandLocal "quickshell-chrismg-config" { } ''
    cp -R ${./quickshell} "$out"
    chmod -R u+w "$out"
    cp ${generatedTheme} "$out/Theme.qml"
  '';
in
{
  # Font Awesome supplies the bar's icons. Theme.qml names its "Free Solid" and
  # "Brands" fonts. theme.nix turns on fontconfig, which lets the bar find them.
  home.packages = [ pkgs.font-awesome ];

  # Installs Quickshell and runs `quickshell --config chrismg` as a systemd user
  # service that starts with the niri session. systemd restarts it if it
  # crashes. cava does not need to be installed, because Theme.qml refers to it
  # by its store path.
  programs.quickshell = {
    enable = true;
    # The folder name under ~/.config/quickshell that the service loads.
    activeConfig = "chrismg";
    systemd.enable = true;
  };

  # Stop the bar when the session ends. Without this, logging out leaves it
  # running with no screen to draw on, and systemd keeps restarting it. The
  # Vicinae and swaync services already have this.
  systemd.user.services.quickshell.Unit.PartOf = [ config.programs.quickshell.systemd.target ];

  # Puts the bar's files in ~/.config/quickshell/chrismg. This is done here
  # instead of with `programs.quickshell.configs`, which would link the whole
  # folder at once. `recursive` links each file on its own, which keeps the
  # existing folder in place.
  xdg.configFile."quickshell/chrismg" = {
    source = quickshellConfig;
    recursive = true;
  };
}
