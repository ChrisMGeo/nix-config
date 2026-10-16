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
# The login screen uses the Theme.qml of the user `chrismg`'s Quickshell bar,
# so its colors, font, and sizes always match the desktop. The cursor and
# wallpaper also come from that user's Home Manager settings. See
# users/chrismg/quickshell.nix, users/chrismg/theme.nix, and
# users/chrismg/wallpaper.nix under hosts/nixos/.
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

  # The fonts the login screen draws with. The greeter does not run as
  # `chrismg`, so it cannot use the fonts in that user's profile. They are
  # installed for the whole system below.
  sansSerif = home.stylix.fonts.sansSerif;

  niri = "${config.programs.niri.package}/bin/niri";

  # Greeter.qml holds the few values only the login screen needs. Every color
  # and size comes from the bar's Theme.qml instead. `${...}` inserts a Nix
  # value into the text.
  greeterSettings = pkgs.writeText "quickshell-greeter-settings.qml" ''
    pragma Singleton

    import QtQuick

    QtObject {
        // The picture behind the login form, already the size of the screen.
        property url wallpaper: "file://${home.stylix.image}"
        // Filled in as the user name.
        property string defaultUser: ${builtins.toJSON user}
        // What greetd runs after a successful login. niri-session starts niri
        // as a systemd user service, so services such as the notification
        // center start with it.
        property var sessionCommand: [${builtins.toJSON "${config.programs.niri.package}/bin/niri-session"}]
    }
  '';

  # One folder with shell.qml, the bar's Theme.qml, Greeter.qml, and a qmldir
  # file that names Theme and Greeter as singletons, which QML files can use
  # by name. The bar's Theme.qml also holds paths to the bar's helper
  # programs, such as cava. The login screen never runs them.
  # `runCommandLocal` runs a small shell script that builds the folder in
  # `$out`.
  greeterConfig = pkgs.runCommandLocal "quickshell-greeter-config" { } ''
    mkdir "$out"
    cp ${./greeter/shell.qml} "$out/shell.qml"
    cp ${home.lib.quickshell.themeFile} "$out/Theme.qml"
    cp ${greeterSettings} "$out/Greeter.qml"
    printf '%s\n' "singleton Theme 1.0 Theme.qml" "singleton Greeter 1.0 Greeter.qml" > "$out/qmldir"
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
