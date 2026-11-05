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

  # The name of the chosen wallpaper in wallpapers/default.nix. Change it to
  # switch wallpapers.
  name = "monochrome-mountain-in-the-void";

  # The chosen wallpaper, at full size. `wallpapers.${name}` looks up the entry
  # whose name is the value of `name`. The picture is already edited, with
  # darker blacks and a little sharpening, so it is used as it is. It is not
  # shrunk to a monitor's size, so it works on any monitor without a list of
  # resolutions. wpaperd shrinks it to each screen when it draws it.
  picture = wallpapers.${name};
in
{
  # The wallpaper picture. Stylix passes it to the programs it themes: wpaperd
  # below, and swaylock in lock.nix, which shows it on the lock screen. The
  # colors stay the ones set in theme.nix, because base16Scheme is set there.
  stylix.image = picture;

  # Fills each monitor with the picture and keeps its proportions. Parts that do
  # not fit the screen's shape are cut off evenly from both sides.
  stylix.imageScalingMode = "fill";

  # wpaperd draws the wallpaper. It runs as a systemd user service that starts
  # with the niri session. Stylix writes its settings from `stylix.image`.
  services.wpaperd.enable = true;

  # Starts wpaperd with niri, the same way the Quickshell bar does in
  # quickshell.nix. Otherwise a second login can skip it, because the session
  # target is still active from the first.
  systemd.user.services.wpaperd = {
    Unit.After = [ "niri.service" ];
    Install.WantedBy = [ "niri.service" ];
  };
}
