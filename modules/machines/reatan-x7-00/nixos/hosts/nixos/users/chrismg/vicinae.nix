# The Vicinae app launcher for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module. The Vicinae server runs as a systemd user
# service from login, and niri.nix opens the launcher with Mod+D.
#
# `{ config, inputs, pkgs, ... }:` makes this file a function. `config` is this
# user's final Home Manager settings. `inputs` is the flake's inputs, which
# machines.nix passes to Home Manager. `pkgs` is the package set.
{ config, inputs, pkgs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The platform of this machine, such as "x86_64-linux". Used to pick the
  # matching package set below.
  system = pkgs.stdenv.hostPlatform.system;

  # The nixpkgs-unstable package set. `.${system}` picks the set for `system`.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in

{
  programs.vicinae = {
    enable = true;

    # Vicinae from nixpkgs-unstable. The stable set has 0.23, which is too old
    # for some of the community extensions.
    package = unstable.vicinae;

    # Runs `vicinae server` as a systemd user service that starts with the niri
    # session. systemd restarts it if it crashes, and restarts it when its
    # settings change.
    systemd.enable = true;

    # Stylix sets the Vicinae colors but not the font, so set the font here.
    settings.font.normal = {
      family = config.stylix.fonts.sansSerif.name;
      size = config.stylix.fonts.sizes.popups;
    };

    settings.launcher_window = {
      # Rounded corners, to match the niri windows. look.cornerRadius comes
      # from look.nix.
      rounding = config.look.cornerRadius;
      # A thin border around the launcher, look.thinBorderWidth from look.nix.
      client_side_decorations.border_width = config.look.thinBorderWidth;
      # Layer shell lets the launcher float above windows like a panel, instead
      # of opening as a normal window that niri would tile.
      layer_shell = {
        enabled = true;
        # Takes the keyboard while open, and lets it go when closed.
        keyboard_interactivity = "on_demand";
      };
    };
  };
}
