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

    # Lets this computer only send sound to Bluetooth devices, not receive it.
    # By default it can do both. Bose QC headphones offer both directions too,
    # so BlueZ picked the wrong one and the headphones sent sound to the
    # computer. They then had a microphone but no speaker output.
    #
    # The roles that stay:
    #   a2dp_source  Sends music-quality sound to headphones and speakers.
    #   hfp_ag       Acts as the phone in a hands-free call, which gives
    #                headsets a microphone.
    #   bap_source, bap_sink  The same for LE Audio devices.
    # The roles removed, a2dp_sink and hfp_hf, would let a phone play its
    # sound through this computer.
    #
    # `extraConfig` writes a WirePlumber settings file. The name after it,
    # "51-bluez-roles", is the file name. The number orders the file after the
    # defaults.
    wireplumber.extraConfig."51-bluez-roles" = {
      "monitor.bluez.properties" = {
        "bluez5.roles" = [ "a2dp_source" "bap_source" "bap_sink" "hfp_ag" ];
      };
    };
  };
}
