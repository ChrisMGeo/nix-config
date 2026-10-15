# Bluetooth for NixOS hosts on the machine reatan-x7-00.
#
# `{ pkgs, ... }:` makes this file a function. `pkgs` is the package set.
{ pkgs, ... }:

{
  # Turns on the Bluetooth adapter and BlueZ, the Linux Bluetooth service.
  # Programs such as the Quickshell bar talk to BlueZ to show the adapter and
  # switch it on and off.
  hardware.bluetooth.enable = true;

  # A pairing agent for every user who logs in. BlueZ refuses to pair a new
  # device unless a program has signed up to answer its pairing questions. The
  # Quickshell bar cannot do that, so its Pair button failed with
  # "Authentication Rejected" without this.
  #
  # bt-agent, from bluez-tools, signs up as the default agent and says it has
  # no screen and no keyboard (NoInputNoOutput). Headphones, speakers, mice,
  # and game controllers then pair without a question. Devices that need a
  # typed PIN, such as some keyboards, are refused. Pair those with
  # bluetoothctl. The adapter is not discoverable, so strangers cannot start a
  # pairing.
  #
  # `systemd.user.services` defines a service that runs once per logged-in
  # user, not once for the whole system.
  systemd.user.services.bluetooth-agent = {
    description = "Bluetooth pairing agent for pairings started on this computer";
    # Starts at login.
    wantedBy = [ "default.target" ];
    serviceConfig = {
      # `--daemon` stops bt-agent from asking questions in a terminal it does
      # not have. It also makes bt-agent move itself to the background, which
      # `forking` tells systemd to expect.
      Type = "forking";
      ExecStart = "${pkgs.bluez-tools}/bin/bt-agent --capability=NoInputNoOutput --daemon";
      Restart = "on-failure";
      # bt-agent ignores the normal stop signal, so systemd would wait its
      # default 90 seconds at logout before killing it. This cuts the wait to
      # 3 seconds.
      TimeoutStopSec = 3;
    };
  };
}
