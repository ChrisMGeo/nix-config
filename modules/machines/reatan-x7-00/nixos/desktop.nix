# The graphical desktop for NixOS hosts on the machine reatan-x7-00.
# niri is the desktop. It is a Wayland compositor that places windows in columns
# on a strip that scrolls sideways. greetd with tuigreet is the login screen
# that starts it.
#
# niri only draws and arranges windows. A bar, a launcher, and notifications are
# separate programs, set up per user in Home Manager.
#
# `{ config, pkgs, ... }:` makes this file a function. `config` is the whole
# system's final settings, and `pkgs` is the package set.
{ config, pkgs, ... }:

{
  # Installs niri and adds it as a session. The nixpkgs module also turns on the
  # GNOME keyring for saved passwords and the screen sharing portals.
  programs.niri.enable = true;

  # greetd is a small login service. It runs one program, the greeter, that asks
  # for the user name and password and then starts the desktop.
  services.greetd = {
    enable = true;

    # tuigreet draws on the text console. This keeps boot and service messages
    # from being printed over it, which would scramble the login screen.
    useTextGreeter = true;
    settings.default_session = {
      # tuigreet is a text-mode greeter.
      #   --time        Shows the clock.
      #   --remember    Fills in the last user name.
      #   --cmd         The program to start after login. niri-session starts niri
      #                 as a systemd user service, so services such as the
      #                 notification center start with it.
      # `${...}` inserts the path of each program into the text.
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.niri.package}/bin/niri-session";
      # The greeter runs as the unprivileged `greeter` account, which the
      # greetd module creates.
      user = "greeter";
    };
  };

  environment.systemPackages = [
    # Lets older X11 programs run under niri. niri starts it on demand when it
    # finds it on the PATH.
    pkgs.xwayland-satellite
  ];

  # Soteria shows the password prompt when a program asks for administrator
  # rights. GNOME had its own prompt, but niri does not.
  security.soteria.enable = true;

  # dconf stores settings for GTK programs. Home Manager writes the GTK theme
  # there, so it must exist without GNOME.
  programs.dconf.enable = true;
}
