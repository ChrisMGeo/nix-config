# The desktop wallpaper for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module, like every .nix file in this folder.
#
# The pictures live in the `wallpapers/` folder at the root of the repository, so
# any user can reuse them. Stylix holds the chosen picture, and wpaperd draws it
# behind the windows on every monitor. niri does not draw a wallpaper by itself.
#
# `{ inputs, ... }:` makes this file a function. `inputs` is the flake's inputs.
{ inputs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # `inputs.self` is this repository. `"${inputs.self}/wallpapers"` is the path
  # of the `wallpapers/` folder inside it, and `import` loads its default.nix:
  # a set that maps each wallpaper's name to its picture.
  wallpapers = import "${inputs.self}/wallpapers";
in
{
  # The wallpaper picture. Stylix passes it to the programs it themes: wpaperd
  # below, and swaylock in lock.nix, which shows it on the lock screen. Stylix
  # also makes the color scheme from it, because theme.nix sets no fixed scheme.
  stylix.image = wallpapers.wallhaven-gwd987;

  # Fills each monitor with the picture and keeps its proportions. Parts that do
  # not fit the screen are cut off.
  stylix.imageScalingMode = "fill";

  # wpaperd draws the wallpaper. It runs as a systemd user service that starts
  # with the niri session. Stylix writes its settings from `stylix.image`.
  services.wpaperd.enable = true;
}
