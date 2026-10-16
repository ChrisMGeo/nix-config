# The graphical desktop for NixOS hosts on the machine reatan-x7-00.
# niri is the desktop. It is a Wayland compositor that places windows in columns
# on a strip that scrolls sideways. The login screen that starts it is in
# greeter.nix.
#
# niri only draws and arranges windows. A bar, a launcher, and notifications are
# separate programs, set up per user in Home Manager.
#
# `{ pkgs, ... }:` makes this file a function. `pkgs` is the package set.
{ pkgs, ... }:

{
  # Installs niri and adds it as a session. The nixpkgs module also turns on the
  # GNOME keyring for saved passwords and the screen sharing portals.
  programs.niri.enable = true;

  environment.systemPackages = [
    # Lets older X11 programs run under niri. niri starts it on demand when it
    # finds it on the PATH.
    pkgs.xwayland-satellite
  ];

  # Soteria shows the password prompt when a program asks for administrator
  # rights. GNOME had its own prompt, but niri does not.
  security.soteria.enable = true;

  # Lets swaylock, the lock screen, check the user's password. Without this PAM
  # entry swaylock cannot unlock the session. The niri module already adds it,
  # but the lock screen depends on it, so it is set here on purpose.
  security.pam.services.swaylock = { };

  # dconf stores settings for GTK programs. Home Manager writes the GTK theme
  # there, so it must exist without GNOME.
  programs.dconf.enable = true;
}
