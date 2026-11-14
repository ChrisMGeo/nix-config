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
  # bluetoothctl.
  #
  # The agent accepts pairing requests from any device, so it does not run all
  # the time. It is not started at login. The Quickshell bar starts it while a
  # scan runs or a pairing from the bar is in progress, and stops it afterward.
  # The bar's own service also stops it whenever the bar starts or stops,
  # including after a crash. See users/chrismg/quickshell.nix under hosts/nixos/.
  #
  # `systemd.user.services` defines a service that runs once per logged-in
  # user, not once for the whole system.
  systemd.user.services.bluetooth-agent = {
    description = "Bluetooth pairing agent, run by the Quickshell bar while it scans or pairs";
    serviceConfig = {
      # `--daemon` stops bt-agent from asking questions in a terminal it does
      # not have. It also makes bt-agent move itself to the background, which
      # `forking` tells systemd to expect.
      Type = "forking";
      # bt-agent signs up with BlueZ before it moves to the background, so
      # `systemctl start` returns only once the agent is ready. The bar waits
      # for that before it pairs.
      ExecStart = "${pkgs.bluez-tools}/bin/bt-agent --capability=NoInputNoOutput --daemon";
      # A last safety net. If the bar is gone and nothing stops the agent, for
      # example a test copy of the bar that quit, systemd stops it after 10
      # minutes. A scan stops by itself after 1 minute, and a pairing takes
      # seconds, so this never cuts off normal use. The bar starts the agent
      # again before every pairing, in case this limit stopped it.
      RuntimeMaxSec = 600;
      # Not restarted after it stops. With `on-failure`, systemd would treat
      # the time limit above as a failure and start the agent again.
      Restart = "no";
      # bt-agent ignores the normal stop signal, SIGTERM, so systemd waited
      # 3 seconds and then killed it with SIGKILL, and marked the service as
      # failed. Sending SIGKILL at once ends the same way, without the wait.
      # BlueZ forgets the agent as soon as its process is gone, so nothing is
      # lost. The bar stops the agent after every scan, and a Pair right after
      # would otherwise wait for those 3 seconds.
      KillSignal = "SIGKILL";
      # Counts the end by SIGKILL as a normal stop, not a failure.
      SuccessExitStatus = "SIGKILL";
    };
  };
}
