# The graphical desktop for NixOS hosts on the machine reatan-x7-00.
# GNOME is the desktop, and GDM is the login screen that starts it.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # GDM (GNOME Display Manager) draws the login screen and starts the desktop
  # after you sign in.
  services.displayManager.gdm.enable = true;

  # GNOME provides the windows, the top bar, and the Settings app.
  services.desktopManager.gnome.enable = true;
}
