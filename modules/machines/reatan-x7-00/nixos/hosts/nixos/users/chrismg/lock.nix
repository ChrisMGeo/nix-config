# The lock screen for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module.
#
# The screen locks only when asked: with Mod+Alt+L in niri.nix, or with Lock in
# the bar's power menu. Nothing locks it or turns the monitors off after a period
# of inactivity. Locking only covers the screen. Programs keep running.
#
# Both ways of locking run `loginctl lock-session`, which asks logind to lock.
# logind then sends a "lock" event, and swayidle starts swaylock for it. swayidle
# is a small helper that turns such events into commands. Here it has no idle
# timers.
#
# `{ config, osConfig, ... }:` makes this file a function. `config` is this
# user's final Home Manager settings. `osConfig` is the whole system's final
# settings.
{ config, osConfig, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # Full paths to the programs below. `${...}` inserts a package's store path.
  swaylock = "${config.programs.swaylock.package}/bin/swaylock";
  loginctl = "${osConfig.systemd.package}/bin/loginctl";
in
{
  # The lock screen. Stylix sets its colors and its background picture. See
  # theme.nix and wallpaper.nix. swaylock checks the password through PAM, which
  # desktop.nix sets up.
  programs.swaylock = {
    enable = true;
    settings = {
      # Pressing Enter with an empty password does nothing, instead of counting
      # as a failed attempt.
      ignore-empty-password = true;
      # Shows how many wrong passwords were typed.
      show-failed-attempts = true;
    };
  };

  # Runs as a systemd user service that starts with the niri session.
  services.swayidle = {
    enable = true;

    # No idle timers: the screen never locks or turns off by itself.
    timeouts = [ ];

    events = {
      # logind asked to lock, for example from `loginctl lock-session`. `-f` makes
      # swaylock fork once the screen is locked, so swayidle does not wait on it.
      lock = "${swaylock} -f";
      # Lock before the computer sleeps. Sleep is off on this desktop, but this
      # keeps a laptop safe.
      before-sleep = "${loginctl} lock-session";
    };
  };
}
