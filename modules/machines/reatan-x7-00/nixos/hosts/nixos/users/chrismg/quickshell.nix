# The Quickshell bar for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module.
#
# Quickshell draws desktop panels from QML files. The QML files live in the
# quickshell/ folder next to this file. This file copies them to
# ~/.config/quickshell/chrismg and adds a generated Theme.qml with the Stylix
# colors, the paths to cava, the audio visualizer, and its settings file,
# quickshell/cava.conf, the paths to nmcli and a script that joins enterprise
# Wi-Fi networks, and the path to a script that reads processes and sensors
# for the activity monitor. The bar runs as a systemd user service from login.
#
# The bar works on any computer. It shows the battery level only when
# `machine.formFactor` is "laptop". See modules/features/nixos/form-factor.nix.
#
# `{ config, osConfig, pkgs, unstable, ... }:` makes this file a function.
# `config` is this user's final Home Manager settings. `osConfig` is the whole
# system's final settings. `pkgs` is the package set. `unstable` is the
# nixpkgs-unstable package set, which machines.nix passes to Home Manager.
{ config, osConfig, pkgs, unstable, ... }:

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

  # Prints the details for the activity monitor window, one item per line. The
  # window runs it every 2 seconds while it is open, and computes percentages
  # from the change between two readings. Each line starts with a word that
  # says what it holds:
  #
  #   core cpu3 <total time> <idle time>   one line per CPU core, plus "cpu" for all of them
  #   uptime <seconds>
  #   load <1 minute> <5 minutes> <15 minutes>
  #   memory <cached bytes> <swap used bytes> <swap total bytes>
  #   cpumodel <name>
  #   cpufreq <average kHz>
  #   cputemp <millidegrees>               only when a CPU sensor exists
  #   gputemp <millidegrees>, gpupower <microwatts>, gpuclock <Hz>
  #   clock <seconds since 1970>
  #   proc <pid> <CPU time> <memory bytes> <GPU time> <video memory bytes> <name>
  #
  # CPU times are in clock ticks, the unit of /proc/stat. GPU time is in
  # nanoseconds. Kernel threads use no memory of their own, so they are left
  # out of the process list.
  # `''${...}` keeps Nix from reading a shell `${...}` as its own.
  activityReader = pkgs.writeShellScript "quickshell-activity" ''
    while read -r name user nice system idle iowait irq softirq steal _; do
      case "$name" in
        cpu*) printf 'core %s %s %s\n' "$name" \
          "$((user + nice + system + idle + iowait + irq + softirq + steal))" \
          "$((idle + iowait))" ;;
        *) break ;;
      esac
    done < /proc/stat

    read -r up _ < /proc/uptime
    printf 'uptime %s\n' "''${up%.*}"
    read -r load1 load5 load15 _ < /proc/loadavg
    printf 'load %s %s %s\n' "$load1" "$load5" "$load15"

    cached=0
    swap_total=0
    swap_free=0
    while read -r key value _; do
      case "$key" in
        Cached:|Buffers:) cached=$((cached + value)) ;;
        SwapTotal:) swap_total=$value ;;
        SwapFree:) swap_free=$value ;;
      esac
    done < /proc/meminfo
    printf 'memory %s %s %s\n' "$((cached * 1024))" \
      "$(((swap_total - swap_free) * 1024))" "$((swap_total * 1024))"

    while IFS=: read -r key value; do
      case "$key" in
        "model name"*) printf 'cpumodel%s\n' "$value"; break ;;
      esac
    done < /proc/cpuinfo

    freq_sum=0
    freq_count=0
    for file in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
      read -r freq 2>/dev/null < "$file" || continue
      freq_sum=$((freq_sum + freq))
      freq_count=$((freq_count + 1))
    done
    [ "$freq_count" -gt 0 ] && printf 'cpufreq %s\n' "$((freq_sum / freq_count))"

    # Temperature sensors. k10temp is AMD's CPU sensor, coretemp Intel's.
    for sensor in /sys/class/hwmon/hwmon*; do
      read -r sensor_name 2>/dev/null < "$sensor/name" || continue
      case "$sensor_name" in
        k10temp|coretemp|zenpower)
          read -r value 2>/dev/null < "$sensor/temp1_input" && printf 'cputemp %s\n' "$value" ;;
        amdgpu)
          read -r value 2>/dev/null < "$sensor/temp1_input" && printf 'gputemp %s\n' "$value"
          { read -r value 2>/dev/null < "$sensor/power1_average" \
            || read -r value 2>/dev/null < "$sensor/power1_input"; } \
            && printf 'gpupower %s\n' "$value"
          read -r value 2>/dev/null < "$sensor/freq1_input" && printf 'gpuclock %s\n' "$value" ;;
      esac
    done

    # The time of this reading in seconds, with microseconds, so the window
    # can turn GPU time into a percentage. `EPOCHREALTIME` is built into bash.
    printf 'clock %s\n' "$EPOCHREALTIME"

    # GPU use per process, read before the process list. Each open GPU device
    # is a file descriptor that links to /dev/dri, and its fdinfo file holds
    # the GPU time in nanoseconds, split by engine, and the video memory in
    # KiB. find lists only those file descriptors, and one grep reads all their
    # fdinfo files, which is much faster than checking every file descriptor
    # in bash. Other users' processes cannot be read, so they count as no GPU
    # use. grep prints each line as `<file>:<key>:<value>`.
    #
    # A program can hold one GPU connection in several file descriptors, or
    # pass it to a child process, so each connection's ID is counted once. The
    # ID is the first of these lines in each file. `declare -A` makes a lookup
    # table: `gpu_clients` holds the IDs already counted, and the other two
    # hold each process's totals.
    declare -A gpu_clients gpu_time_of vram_of
    file_seen=""
    skip=1
    while IFS=: read -r file key value; do
      pid=''${file#/proc/}
      pid=''${pid%%/*}
      # Keeps only the digits, which drops the tab and the unit.
      value=''${value//[!0-9]/}
      # A file without an ID is skipped, as is one whose ID was counted.
      if [ "$file" != "$file_seen" ]; then
        file_seen=$file
        skip=1
      fi
      case "$key" in
        drm-client-id)
          if [ -z "''${gpu_clients[$value]}" ]; then
            gpu_clients[$value]=1
            skip=0
          fi ;;
        # Intel also lists drm-engine-capacity-* lines. They count engine
        # copies, not time, so they are skipped. The pattern below would
        # otherwise match them.
        drm-engine-capacity-*) ;;
        drm-engine-*)
          [ "$skip" = 0 ] && gpu_time_of[$pid]=$((''${gpu_time_of[$pid]:-0} + value)) ;;
        drm-resident-vram)
          [ "$skip" = 0 ] && vram_of[$pid]=$((''${vram_of[$pid]:-0} + value * 1024)) ;;
      esac
    done < <(${pkgs.findutils}/bin/find /proc/[0-9]*/fd -lname '/dev/dri/*' \
        -printf '%h/../fdinfo/%f\0' 2>/dev/null \
      | ${pkgs.findutils}/bin/xargs -0 -r ${pkgs.gnugrep}/bin/grep -H -E \
        '^drm-(client-id:|engine-|resident-vram:)' 2>/dev/null)

    # One line per process.
    for stat in /proc/[0-9]*/stat; do
      # The process can exit between the glob and the read.
      read -r line 2>/dev/null < "$stat" || continue
      dir=''${stat%/stat}
      pid=''${dir#/proc/}

      # The second field is the short name in parentheses, which can hold
      # spaces. `fields=(...)` splits what follows it at spaces into the list
      # `fields`, which starts with the third field and counts from 0. utime
      # and stime, fields 14 and 15, are fields[11] and fields[12]. It is
      # faster than `read -ra` with `<<<`, which writes a temporary file for
      # every process.
      comm=''${line#*(}
      comm=''${comm%)*}
      fields=(''${line##*) })
      time=$((fields[11] + fields[12]))

      # Memory is the resident pages minus the shared ones, in 4 KiB pages,
      # as GNOME System Monitor shows it. Counting shared pages would count a
      # library or a browser's shared memory once for every process that maps
      # it, and the rows would add up to more than the RAM in use.
      resident=0
      shared=0
      read -r _ resident shared _ 2>/dev/null < "$dir/statm"
      [ "$resident" -gt 0 ] || continue

      # GPU use, from the tables filled in above.
      gpu_time=''${gpu_time_of[$pid]:-0}
      vram=''${vram_of[$pid]:-0}

      # The short name is cut to 15 characters, so prefer the program's file
      # name from the first word of its command line. Nix wrappers start the
      # real program with the wrapper's name as that word. Some programs, such
      # as Brave, rewrite their command line as one string with spaces, so cut
      # at the first space before taking the part after the last slash.
      arg0=""
      read -r -d "" arg0 2>/dev/null < "$dir/cmdline"
      name=''${arg0%% *}
      name=''${name%%:*}
      name=''${name##*/}
      printf 'proc %s %s %s %s %s %s\n' "$pid" "$time" \
        "$(((resident - shared) * 4096))" "$gpu_time" "$vram" "''${name:-$comm}"
    done
  '';

  # Exits with 0 when power-profiles-daemon is running. The bar uses it to decide
  # whether to show the profile buttons.
  powerProfilesProbe = pkgs.writeShellScript "quickshell-power-profiles-available" ''
    ${osConfig.systemd.package}/bin/busctl --system --quiet status net.hadess.PowerProfiles \
      >/dev/null 2>&1
  '';

  # The nmcli that matches the NetworkManager the system runs. The settings
  # drawer uses it to rescan for Wi-Fi networks.
  nmcli = "${osConfig.networking.networkmanager.package}/bin/nmcli";

  # The file with every certificate authority the system trusts, such as
  # /etc/ssl/certs/ca-certificates.crt. NixOS writes it into /etc with
  # `environment.etc`, and `target` is its place under /etc. Reading the name
  # from the system settings, instead of typing the path, makes evaluation stop
  # if NixOS ever stops providing the file. The path under /etc stays the same
  # when the certificates are updated, unlike a path in the Nix store, which a
  # saved Wi-Fi profile would keep pointing at after it is deleted.
  caBundle = "/etc/${osConfig.environment.etc."ssl/certs/ca-certificates.crt".target}";

  # Saves and joins an enterprise Wi-Fi network, such as eduroam, that logs in
  # with a username and a password. Quickshell can only join networks that use
  # one password, so the settings drawer runs this for the others.
  #
  # Arguments: the network name, the Wi-Fi card name, the username, and the
  # server's domain. The password comes as one line on stdin, so it never shows
  # in the process list. It uses PEAP with MSCHAPv2, which most of these
  # networks use.
  # The domain is required. NetworkManager checks the server's certificate
  # against the certificate authorities in `caBundle` above (`ca-cert`), and only
  # accepts a certificate whose name ends in that domain (`domain-suffix-match`).
  # Without this check, a fake access point with the same name could collect
  # the password.
  # NetworkManager's own `system-ca-certs` option is turned off on purpose. It
  # points at the folder /etc/ssl/certs, and a folder only works if it holds one
  # file per certificate, named by a hash. NixOS keeps only bundle files there,
  # so no certificate would be found and every join would fail. Setting it to
  # `no` also clears it on a profile that an older version of this script saved.
  # `password-flags 0` lets NetworkManager save the password, so the next
  # connection does not ask again. The password reaches NetworkManager through
  # `passwd-file`, which nmcli reads from stdin here. If a saved connection with
  # the name exists, its settings are updated instead of adding a second one.
  # `''${...}` keeps Nix from reading a shell `${...}` as its own.
  wifiEnterpriseJoin = pkgs.writeShellScript "quickshell-wifi-enterprise-join" ''
    set -eu
    ssid=$1
    interface=$2
    identity=$3
    domain=$4
    IFS= read -r password

    if [ -z "$domain" ]; then
      echo "Enter the server domain, such as radius.example.edu." >&2
      exit 1
    fi

    settings=(
      wifi-sec.key-mgmt wpa-eap
      802-1x.eap peap
      802-1x.phase2-auth mschapv2
      802-1x.identity "$identity"
      802-1x.system-ca-certs no
      802-1x.ca-cert ${caBundle}
      802-1x.domain-suffix-match "$domain"
      802-1x.password-flags 0
    )

    if ${nmcli} connection show id "$ssid" >/dev/null 2>&1; then
      ${nmcli} connection modify id "$ssid" "''${settings[@]}"
    else
      ${nmcli} connection add type wifi con-name "$ssid" ifname "$interface" \
        ssid "$ssid" "''${settings[@]}"
    fi

    printf '802-1x.password:%s\n' "$password" \
      | ${nmcli} --wait 45 connection up id "$ssid" passwd-file /dev/stdin
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
        property string activityCommand: "${activityReader}"
        property string powerProfilesCommand: "${powerProfilesProbe}"
        property string nmcliCommand: "${nmcli}"
        property string wifiEnterpriseCommand: "${wifiEnterpriseJoin}"
        // The programs the bar and the login screen start, by exact store
        // path, so they do not depend on what is in PATH. systemctl and
        // loginctl come from the system's systemd, and niri from the niri the
        // system runs. systemctl starts and stops the Bluetooth pairing agent
        // in bluetooth.nix, and restarts and shuts down the computer. loginctl
        // locks the session. niri reads workspaces and windows, switches
        // workspaces, and logs out.
        property string systemctlCommand: "${osConfig.systemd.package}/bin/systemctl"
        property string loginctlCommand: "${osConfig.systemd.package}/bin/loginctl"
        property string niriCommand: "${osConfig.programs.niri.package}/bin/niri"
        // Exact store paths, so the visualizer does not depend on any profile.
        property string cavaCommand: "${pkgs.cava}/bin/cava"
        property string cavaConfig: "${cavaConfig}"
        // True on laptops. Desktops hide the battery level. The power profile switch
        // shows on every machine that runs power-profiles-daemon.
        property bool showBattery: ${if osConfig.machine.formFactor == "laptop" then "true" else "false"}
        property real uiScale: 1.15

        function scaled(value) {
            return Math.round(value * uiScale);
        }

        // Stylix Base16 colors.
        // Panels are see-through, like kitty in kitty.nix. niri blurs what
        // shows through, so they look like dark frosted glass. Each window asks
        // for the blur with BackgroundEffect.blurRegion. The opacity is
        // stylix.opacity.popups, set in theme.nix.
        property real panelOpacity: ${toString config.stylix.opacity.popups}
        property color panelSolid: ${color "base00"}
        property color panel: Qt.rgba(panelSolid.r, panelSolid.g, panelSolid.b, panelOpacity)
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

        // The soft light glow around the panels, the same as niri's glow
        // around the focused window. See PanelGlow.qml and ../look.nix. The
        // color is the Stylix base07 color at look.glowAlpha out of 255.
        property color glowBase: ${color "base07"}
        property color glow: Qt.rgba(glowBase.r, glowBase.g, glowBase.b, ${toString config.look.glowAlpha} / 255)
        property int glowSoftness: ${toString config.look.glowSoftness}
        property int glowSpread: ${toString config.look.glowSpread}
        // How far the glow reaches past a panel's edge: the spread plus three
        // sigma, where it has faded to almost nothing. Windows leave this much
        // space around their panels.
        property int glowReach: glowSpread + Math.ceil(glowSoftness * 1.5)

        property int outlineWidth: ${toString config.look.borderWidth}
        property int outerMargin: ${toString config.look.screenMargin}
        property int barTopGap: ${toString config.look.topMargin}
        property int barBottomGap: 8
        property int gap: 8
        property int radius: ${toString config.look.cornerRadius}
        property int barHeight: scaled(46)
        // Where the settings drawer, the power menu, and the tray drop-down
        // start, measured from the top of the screen. They all use it, so
        // the space between them and the bar is the same.
        property int menuTop: barHeight + outerMargin * 2
        property int drawerWidth: scaled(352)
        property int textSize: scaled(13)
        property int topBarIconSize: scaled(11)
        property int spectrumBars: ${toString spectrumBars}
        property int mediaSpectrumBars: 8

        // Where the login screen places its clock card, as a fraction of the
        // screen's width and height. See greeter/shell.qml. The sizes are the
        // login screen card's and the starting sizes of the clock and
        // now-playing windows on the desktop.
        property real clockLeft: 0.11
        property real clockTop: 0.20
        property real clockWidth: scaled(308)
        property real clockHeight: scaled(180)
        property real mediaWidth: scaled(420)
        property real mediaHeight: scaled(292)
    }
  '';

  # One folder with the QML files from quickshell/ plus the generated Theme.qml.
  # `runCommandLocal` runs a small shell script that builds the folder.
  # It also compiles the panel glow shader, glow.frag, to glow.frag.qsb, the
  # form Qt 6 reads. qsb comes from the same nixpkgs-unstable Qt that
  # Quickshell uses. See quickshell/PanelGlow.qml.
  quickshellConfig = pkgs.runCommandLocal "quickshell-chrismg-config" { } ''
    cp -R ${./quickshell} "$out"
    chmod -R u+w "$out"
    cp ${generatedTheme} "$out/Theme.qml"
    ${unstable.qt6.qtshadertools}/bin/qsb --qt6 -o "$out/glow.frag.qsb" "$out/glow.frag"
  '';
in
{
  # Shares the generated Theme.qml with the login screen, so it looks the same
  # as the bar without a copy of every value. `lib` is a Home Manager setting
  # where modules can put values for other modules to read. greeter.nix, at the
  # NixOS level, reads it as `config.home-manager.users.chrismg.lib.quickshell.themeFile`.
  lib.quickshell.themeFile = generatedTheme;
  # Shares the bar's QML folder too, so the login screen can copy small parts
  # such as TextButton.qml instead of keeping its own copies. greeter.nix
  # picks the files.
  lib.quickshell.qmlDir = ./quickshell;

  # Font Awesome supplies the bar's icons. Theme.qml names its "Free Solid" and
  # "Brands" fonts. theme.nix turns on fontconfig, which lets the bar find them.
  home.packages = [ pkgs.font-awesome ];

  # Installs Quickshell and runs `quickshell --config chrismg` as a systemd user
  # service that starts with the niri session. systemd restarts it if it
  # crashes. cava does not need to be installed, because Theme.qml refers to it
  # by its store path.
  programs.quickshell = {
    enable = true;
    # Quickshell 0.3.1 or newer from nixpkgs-unstable. 0.3.0, in the stable
    # set, crashes when a Wi-Fi access point drops out of range, which the
    # network list in the settings drawer makes common. Go back to `pkgs` once
    # stable has 0.3.1.
    package = unstable.quickshell;
    # The folder name under ~/.config/quickshell that the service loads.
    activeConfig = "chrismg";
    systemd.enable = true;
  };

  # Stop the bar when the session ends. Without this, logging out leaves it
  # running with no screen to draw on, and systemd keeps restarting it. The
  # Vicinae and swaync services already have this.
  systemd.user.services.quickshell.Unit.PartOf = [ config.programs.quickshell.systemd.target ];

  # Starts the bar with niri, not only with graphical-session.target. The session
  # target stays active between logins, so a new login does not start the bar
  # again. niri starts after the session sets WAYLAND_DISPLAY, so the bar starts
  # with a screen to draw on. `After` puts the bar's start after niri's, and
  # `WantedBy` makes niri start the bar. The default WantedBy stays in place.
  systemd.user.services.quickshell = {
    Unit.After = [ "niri.service" ];
    Install.WantedBy = [ "niri.service" ];

    # Stops the Bluetooth pairing agent from bluetooth.nix before the bar
    # starts and after it stops. The bar starts the agent only while it scans
    # or pairs, and the agent accepts pairing requests from any device. If the
    # bar crashed or quit while the agent ran, nothing else would stop it.
    # ExecStopPost runs after every stop, even a crash, and ExecStartPre covers
    # a bar that was started some other way and left it running.
    # The `-` in front lets the bar start even if systemctl fails, and
    # `--no-block` returns without waiting for the agent to stop.
    Service.ExecStartPre = [ "-${osConfig.systemd.package}/bin/systemctl --user --no-block stop bluetooth-agent.service" ];
    Service.ExecStopPost = [ "-${osConfig.systemd.package}/bin/systemctl --user --no-block stop bluetooth-agent.service" ];
  };

  # Puts the bar's files in ~/.config/quickshell/chrismg, the folder named by
  # `activeConfig` above. This is done here instead of with
  # `programs.quickshell.configs`, which would link the whole folder at once.
  # `recursive` links each file on its own, which keeps the existing folder in
  # place.
  xdg.configFile."quickshell/${config.programs.quickshell.activeConfig}" = {
    source = quickshellConfig;
    recursive = true;
  };
}
