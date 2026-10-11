# Sound setup for NixOS hosts on the machine reatan-x7-00.
# PipeWire is the sound server. It replaces the older PulseAudio server.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # Turns off the older PulseAudio server. Only one sound server runs at a time,
  # so PipeWire takes its place.
  services.pulseaudio.enable = false;

  # RealtimeKit lets PipeWire request a higher scheduling priority. That keeps
  # audio smooth when the system is busy.
  security.rtkit.enable = true;

  services.pipewire = {
    # Turns on PipeWire.
    enable = true;

    # Provides the ALSA interface, which many low-level audio programs use.
    alsa.enable = true;
    # Also serves 32-bit programs, such as some older games.
    alsa.support32Bit = true;

    # Provides the PulseAudio interface, so apps written for PulseAudio keep working.
    pulse.enable = true;
  };
}
