# The login screen for NixOS hosts on the machine reatan-x7-00. Loaded by
# machines.nix, like every .nix file in this folder.
#
# greetd is a small login service. It runs one program, the greeter, that asks
# for the user name and password and then starts the desktop. Here the greeter
# is a Quickshell login screen that looks like the Quickshell bar of the
# desktop. Quickshell needs a Wayland compositor to draw in, so greetd starts
# niri with its own small settings file, greeter/niri.kdl, and niri starts
# Quickshell. The QML file is greeter/shell.qml.
#
# The colors, font, cursor, and wallpaper come from the Home Manager settings
# of the user `chrismg`, so the login screen changes with the desktop. See
# users/chrismg/theme.nix and users/chrismg/wallpaper.nix under hosts/nixos/.
#
# `{ config, pkgs, ... }:` makes this file a function. `config` is the whole
# system's final settings, and `pkgs` is the package set.
{ config, pkgs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The user whose look the login screen copies, and who is filled in as the
  # user name. `config.home-manager.users.${user}` is that user's final Home
  # Manager settings. `${user}` looks up the entry named by `user`.
  user = "chrismg";
  home = config.home-manager.users.${user};

  # The Stylix colors as "#rrggbb" strings.
  colors = home.lib.stylix.colors.withHashtag;
  # Turns a Stylix color slot, such as "base00", into a quoted QML string.
  # `builtins.toJSON` adds the quotes.
  color = slot: builtins.toJSON colors.${slot};

  # The fonts the login screen draws with. The greeter does not run as
  # `chrismg`, so it cannot use the fonts in that user's profile. They are
  # installed for the whole system below.
  sansSerif = home.stylix.fonts.sansSerif;

  niri = "${config.programs.niri.package}/bin/niri";

  # Theme.qml holds every color, size, and path that shell.qml uses. The sizes
  # and colors match Theme.qml of the desktop bar, in users/chrismg/quickshell.nix.
  # Keep the two in step. `${...}` inserts a Nix value into the text.
  generatedTheme = pkgs.writeText "quickshell-greeter-theme.qml" ''
    pragma Singleton

    import QtQuick

    QtObject {
        property string fontFamily: ${builtins.toJSON sansSerif.name}
        property string iconFontFamily: "Font Awesome 7 Free Solid"
        property real uiScale: 1.15

        function scaled(value) {
            return Math.round(value * uiScale);
        }

        // The picture behind the login form, already the size of the screen.
        property url wallpaper: "file://${home.stylix.image}"
        // Filled in as the user name.
        property string defaultUser: ${builtins.toJSON user}
        // What greetd runs after a successful login. niri-session starts niri
        // as a systemd user service, so services such as the notification
        // center start with it.
        property var sessionCommand: [${builtins.toJSON "${config.programs.niri.package}/bin/niri-session"}]

        // Stylix Base16 colors. Panels are 80% opaque black, like the bar.
        property real panelOpacity: 0.8
        property color panelSolid: ${color "base00"}
        property color panel: Qt.rgba(panelSolid.r, panelSolid.g, panelSolid.b, panelOpacity)
        property color surfaceHover: ${color "base02"}
        property color outline: ${color "base03"}
        property color outlineTranslucent: Qt.rgba(outline.r, outline.g, outline.b, 0.55)
        property color subtleButton: Qt.rgba(text.r, text.g, text.b, 0.06)
        property color text: ${color "base05"}
        property color textMuted: ${color "base04"}
        property color accent: ${color "base0D"}
        property color accentText: ${color "base00"}
        property color destructive: ${color "base08"}

        property int outlineWidth: 2
        property int compactOutlineWidth: 1
        property int outerMargin: 12
        property int gap: 8
        property int radius: 12
        property int textSize: scaled(13)

        // The clock card's place, as a fraction of the screen, and size. The
        // same as on the desktop.
        property real clockLeft: 0.11
        property real clockTop: 0.20
        property real clockWidth: scaled(308)
        property real clockHeight: scaled(180)
    }
  '';

  # One folder with shell.qml, a qmldir file that names Theme as a singleton,
  # and the generated Theme.qml. `runCommandLocal` runs a small shell script
  # that builds the folder in `$out`.
  greeterConfig = pkgs.runCommandLocal "quickshell-greeter-config" { } ''
    mkdir "$out"
    cp ${./greeter/shell.qml} "$out/shell.qml"
    cp ${generatedTheme} "$out/Theme.qml"
    echo "singleton Theme 1.0 Theme.qml" > "$out/qmldir"
  '';

  # greeter/niri.kdl with the words between @ signs filled in. `replaceVars`
  # fails the build if the file has a placeholder that is not listed here.
  # `toString` turns the number into text.
  niriConfig = pkgs.replaceVars ./greeter/niri.kdl {
    cursorTheme = home.stylix.cursor.name;
    cursorSize = toString home.stylix.cursor.size;
    greeter = "${pkgs.quickshell}/bin/quickshell --path ${greeterConfig}/shell.qml";
    # `inherit niri;` is short for `niri = niri;`, the path set above.
    inherit niri;
  };
in
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      # `-c` gives niri the login screen's settings instead of a user's.
      command = "${niri} -c ${niriConfig}";
      # The greeter runs as the unprivileged `greeter` account, which the
      # greetd module creates.
      user = "greeter";
    };
  };

  # The login screen's fonts: the user's sans-serif font for text, and Font
  # Awesome for the icons on the buttons.
  fonts.packages = [ sansSerif.package pkgs.font-awesome ];

  # The mouse pointer theme, so niri can find it for the login screen.
  environment.systemPackages = [ home.stylix.cursor.package ];
}
