# Colors and fonts for the user `chrismg` on the host `nixos`, applied by Stylix.
# Loaded by machines.nix as a Home Manager module, like every .nix file in this folder.
#
# Stylix takes one color scheme and one set of fonts and writes matching settings
# for every program it supports that Home Manager turns on, such as GTK and Qt
# apps. Other files read the same colors from `config.lib.stylix.colors`.
#
# `{ inputs, pkgs, ... }:` makes this file a function. `inputs` is the flake's
# inputs, and `pkgs` is the package set.
{ inputs, pkgs, ... }:

{
  # `imports` loads other modules. This one adds the `stylix.*` settings to
  # Home Manager.
  imports = [ inputs.stylix.homeModules.stylix ];

  stylix = {
    enable = true;

    # Stylix normally adds its own nixpkgs overlays. This system shares one nixpkgs
    # between NixOS and Home Manager, so Home Manager may not add overlays.
    overlays.enable = false;

    # Dark mode, for programs that pick a light or dark variant.
    polarity = "dark";

    # A Base16 scheme is 16 colors, base00 to base0F. base00 to base07 run from
    # the background to the brightest text. base08 to base0F are accent colors.
    # This scheme is black and white only, with gray in place of the accents.
    base16Scheme = {
      scheme = "ChrisMG Black Monochrome";
      author = "Chris Mathew George";
      base00 = "000000";
      base01 = "080808";
      base02 = "202020";
      base03 = "767676";
      base04 = "a0a0a0";
      base05 = "d4d4d4";
      base06 = "ebebeb";
      base07 = "ffffff";
      base08 = "b8b8b8";
      base09 = "cccccc";
      base0A = "e0e0e0";
      base0B = "a8a8a8";
      base0C = "c0c0c0";
      base0D = "f0f0f0";
      base0E = "dcdcdc";
      base0F = "909090";
    };

    # Iosevka for every kind of text. `package` is what gets installed. `name` is
    # the font family name that programs ask for.
    fonts = {
      monospace = { package = pkgs.iosevka; name = "Iosevka"; };
      sansSerif = { package = pkgs.iosevka; name = "Iosevka"; };
      serif = { package = pkgs.iosevka; name = "Iosevka"; };
      # Sizes in points.
      sizes.terminal = 13;
      sizes.popups = 13;
    };

    # Theme GTK and Qt apps too. Stylix does not always turn these on by itself
    # outside a full desktop such as GNOME.
    targets.gtk.enable = true;
    targets.qt.enable = true;
  };

  # Lets programs find the fonts that Home Manager installs.
  fonts.fontconfig.enable = true;
}
