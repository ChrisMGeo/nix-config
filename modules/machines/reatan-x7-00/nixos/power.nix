# Power settings for NixOS hosts on the machine reatan-x7-00. This machine is a
# desktop, so it never sleeps. UPower and power-profiles-daemon report power
# state to programs such as the Quickshell bar.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # UPower reports battery and power state over D-Bus. The bar uses it to find
  # out whether a battery exists.
  services.upower.enable = true;

  # power-profiles-daemon switches between performance, balanced, and power-saver.
  # The bar's settings drawer shows the profile and switches it.
  services.power-profiles-daemon.enable = true;

  # Refuses every kind of sleep, so nothing can suspend this desktop.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };
}
