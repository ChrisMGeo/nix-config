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
    # This one is black and white only, with gray in place of the accents. It
    # lives in the root `themes/` folder so other users can reuse it.
    # `inputs.self` is this repository, and `import` loads the scheme file.
    base16Scheme = import "${inputs.self}/themes/black-monochrome.nix";

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

    # The icon theme for GTK and Qt apps and notifications. Without one, apps
    # fall back to `hicolor`, which has almost no icons, so many show a broken
    # image. Papirus is complete and has dark variants. `override` builds the
    # package with a different input. `color = "grey"` recolors its folder
    # icons to match the black and white scheme.
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme.override { color = "grey"; };
      # The variant used with a dark or a light color scheme. polarity above
      # picks dark.
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    # The mouse pointer. Bibata Modern Classic is a plain black pointer with a
    # white outline. niri.nix uses the same name and size.
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      # Size in pixels.
      size = 24;
    };

    # Theme GTK and Qt apps too. Stylix does not always turn these on by itself
    # outside a full desktop such as GNOME.
    targets.gtk.enable = true;
    targets.qt.enable = true;
  };

  # Lets programs find the fonts that Home Manager installs.
  fonts.fontconfig.enable = true;
}
