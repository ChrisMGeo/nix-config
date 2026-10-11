# Declares the `machine.formFactor` setting, which says whether a computer is a
# desktop or a laptop, and adds the laptop power behavior. Loaded for every NixOS
# host, because this file sits in features/nixos/. Each machine sets its own value
# in its platform folder, for example reatan-x7-00/nixos/form-factor.nix.
#
# `{ config, lib, pkgs, ... }:` makes this file a function. `config` is the whole
# system's final settings, `lib` is the nixpkgs helper library, and `pkgs` is the
# package set.
{ config, lib, pkgs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # Sets the power profile from the charger state. power-profiles-daemon must be
  # running. A charger reports itself in /sys/class/power_supply as type "Mains",
  # or "USB" for a USB-C charger, with `online` set to 1 while it is plugged in.
  applyProfile = pkgs.writeShellScript "power-profile-for-ac" ''
    profile=power-saver
    for supply in /sys/class/power_supply/*; do
      type=$(cat "$supply/type" 2>/dev/null)
      online=$(cat "$supply/online" 2>/dev/null)
      if { [ "$type" = Mains ] || [ "$type" = USB ]; } && [ "$online" = 1 ]; then
        profile=performance
      fi
    done
    exec ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$profile"
  '';
in
{
  # `options` declares a new setting. Other files set its value; this file only
  # describes it.
  options.machine.formFactor = lib.mkOption {
    # `enum` allows only the listed strings, so a typo stops evaluation early.
    type = lib.types.enum [ "desktop" "laptop" ];
    # Most settings in this repository were written for a desktop.
    default = "desktop";
    description = "Whether this computer is a desktop or a laptop.";
  };

  # `mkIf cond set` applies `set` only when `cond` is true. These settings apply
  # only to laptops.
  config = lib.mkIf (config.machine.formFactor == "laptop") {
    # UPower reports the battery level to the bar. `mkDefault` lets a machine
    # file turn it off.
    services.upower.enable = lib.mkDefault true;

    # power-profiles-daemon switches between the performance, balanced, and
    # power-saver profiles. The service below depends on it.
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # Runs the script once. It starts at boot and again each time the charger
    # is plugged in or removed.
    systemd.services.power-profile-for-ac = {
      description = "Pick the power profile from the charger state";
      # Start after power-profiles-daemon, because the script talks to it.
      after = [ "power-profiles-daemon.service" ];
      wants = [ "power-profiles-daemon.service" ];
      # `multi-user.target` is the normal running state, so this runs at boot.
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        # The script runs and exits. It is not a long-running program.
        Type = "oneshot";
        ExecStart = applyProfile;
      };
    };

    # udev reacts to hardware events. When a charger changes state, start the
    # service above. The rules match chargers only, because a battery sends
    # change events every few minutes as its level drops. `${...}` inserts the
    # path of the systemctl program into the text.
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ACTION=="change", ATTR{type}=="Mains", RUN+="${config.systemd.package}/bin/systemctl start --no-block power-profile-for-ac.service"
      SUBSYSTEM=="power_supply", ACTION=="change", ATTR{type}=="USB", RUN+="${config.systemd.package}/bin/systemctl start --no-block power-profile-for-ac.service"
    '';
  };
}
