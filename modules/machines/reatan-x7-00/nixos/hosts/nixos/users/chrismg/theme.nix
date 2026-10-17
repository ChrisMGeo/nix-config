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

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # Libron, a serif font made for reading long text on screens. It is a
  # reworked version of Newsreader. nixpkgs does not have it, so this builds a
  # package from the release on GitHub: github.com/nicoverbruggen/libron.
  # `stdenvNoCC.mkDerivation` makes a package without a C compiler, which is
  # enough for copying files. `rec` lets the settings refer to each other, so
  # the download address can use `version`.
  libron = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "libron";
    # The release to download. To update, change this and set `hash` to
    # `pkgs.lib.fakeHash`. The build then fails and prints the correct hash.
    version = "0.31";

    # `Libron.zip` holds the desktop TrueType files. The release also has
    # versions for e-readers and the web, which this system does not need.
    # `${version}` puts the value of `version` into the text.
    # `stripRoot = false` is needed because the files sit at the top of the
    # zip, not inside a folder.
    src = pkgs.fetchzip {
      url = "https://github.com/nicoverbruggen/libron/releases/download/v${version}/Libron.zip";
      stripRoot = false;
      hash = "sha256-UD+8cjdiomyEtGlLtkmcNd8Y8wNU8RIEwyPdq55nm4o=";
    };

    # Copies the fonts to the folder where fontconfig looks for them.
    installPhase = ''
      runHook preInstall
      install -Dm644 -t $out/share/fonts/truetype *.ttf
      runHook postInstall
    '';

    meta.license = pkgs.lib.licenses.ofl;
  };
in
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
    # Because a scheme is set here, Stylix does not make colors from the
    # wallpaper.
    base16Scheme = import "${inputs.self}/themes/black-monochrome.nix";

    # Three fonts. `package` is what gets installed. `name` is the font family
    # name that programs ask for.
    # - Iosevka for monospace text, such as the terminal.
    # - Iosevka Aile for sans-serif text, which covers the bar, the launcher,
    #   notifications, and most app interfaces. It is Iosevka with normal
    #   letter widths instead of fixed ones, so it matches the terminal font.
    #   `iosevka-bin` is the prebuilt release, so nothing has to be compiled.
    #   `override { variant = "Aile"; }` picks the Aile variant of it.
    # - Libron, defined above, for serif text, such as web pages that ask for
    #   a serif font.
    fonts = {
      monospace = { package = pkgs.iosevka; name = "Iosevka"; };
      sansSerif = {
        package = pkgs.iosevka-bin.override { variant = "Aile"; };
        name = "Iosevka Aile";
      };
      serif = { package = libron; name = "Libron"; };
      # Sizes in points.
      sizes.terminal = 13;
      sizes.popups = 13;
    };

    # How opaque popups are, from 0 (invisible) to 1 (solid). Stylix applies
    # it to the Vicinae launcher. quickshell.nix and ../../../../greeter.nix
    # read it for the bar, its panels, and the login screen. At 0.8 the
    # background stays dark enough to read text on, and niri blurs what shows
    # through.
    opacity.popups = 0.8;

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
