# The Vicinae app launcher for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module. The Vicinae server runs as a systemd user
# service from login, and niri.nix opens the launcher with Mod+D.
#
# `{ config, inputs, lib, pkgs, ... }:` makes this file a function. `config` is
# this user's final Home Manager settings. `inputs` is the flake's inputs, which
# machines.nix passes to Home Manager. `lib` is nixpkgs' library of helper
# functions. `pkgs` is the package set.
{ config, inputs, lib, pkgs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The platform of this machine, such as "x86_64-linux". Used to pick the
  # matching package sets below.
  system = pkgs.stdenv.hostPlatform.system;

  # The nixpkgs-unstable package set. `.${system}` picks the set for `system`.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};

  # The extensions from the vicinae-extensions flake, built for this platform.
  # Each one is named after its folder in github.com/vicinaehq/extensions.
  extensions = inputs.vicinae-extensions.packages.${system};
in

{
  programs.vicinae = {
    enable = true;

    # Vicinae from nixpkgs-unstable. The stable set has 0.23, which is too old
    # for the Reminders and Lorem Ipsum extensions below.
    package = unstable.vicinae;

    # Runs `vicinae server` as a systemd user service that starts with the niri
    # session. systemd restarts it if it crashes, and restarts it when its
    # settings or extensions change.
    systemd.enable = true;

    # Extensions to install. Home Manager links each one into
    # ~/.local/share/vicinae/extensions. Their own settings, such as the
    # SuperGenPass master password and the OTP secrets, are entered in Vicinae
    # and stay out of this file, because files here end up readable by every
    # user in the Nix store.
    extensions = [
      # Window and workspace actions for niri, and a color picker.
      extensions.niri
      # Searches nixpkgs packages, NixOS options, and Home Manager options.
      extensions.nix
      # Makes a password for each website from one master password.
      extensions.supergenpass
      # Two-factor login codes.
      extensions.otp
      # Searches and copies text faces such as (^_^).
      extensions.kaomojis
      # Converts numbers between decimal, hexadecimal, binary, and octal.
      extensions.number-converter
      # Placeholder text.
      extensions.lorem-ipsum
      # Reminders with dates in plain words, such as "tomorrow at 9".
      extensions.reminders
    ];

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

  # The Reminders extension needs Node.js 20 or newer to run its timer jobs, and
  # notify-send to show each reminder. Neither is on this user's PATH, so these
  # variables give it their exact paths. Home Manager adds this line to the
  # vicinae service it creates from systemd.enable above.
  # `${...}` inserts a value into a string. `lib.getExe pkgs.nodejs` is the path
  # of the package's main program, and `lib.getExe'` picks a program by name.
  systemd.user.services.vicinae.Service.Environment = [
    "VICINAE_REMINDERS_NODE=${lib.getExe pkgs.nodejs}"
    "VICINAE_REMINDERS_NOTIFY_SEND=${lib.getExe' pkgs.libnotify "notify-send"}"
  ];
}
