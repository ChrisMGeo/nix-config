# The desktop wallpaper for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module, like every .nix file in this folder.
#
# The pictures live in the `wallpapers/` folder at the root of the repository, so
# any user can reuse them. Stylix holds the chosen picture, and wpaperd draws it
# behind the windows on every monitor. niri does not draw a wallpaper by itself.
#
# `{ inputs, pkgs, ... }:` makes this file a function. `inputs` is the flake's
# inputs, and `pkgs` is the package set.
{ inputs, pkgs, ... }:

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
  # whose name is the value of `name`.
  picture = wallpapers.${name};

  # How dark a gray turns fully black, as a percent of full white. The chosen
  # picture's background is nearly black, near 1%, with film grain up to
  # about 8%. Setting this to 10 makes that background and its grain true
  # black and stretches the brighter tones to fill the range, so the picture
  # has more contrast. Set it to 0 to keep the picture's own tones.
  blackPoint = 10;

  # The monitor's resolution in pixels, from `niri msg outputs`. Update it if the
  # monitor changes.
  screen = { width = 2560; height = 1440; };

  # Shrinks a picture to exactly the screen size, at build time. wpaperd scales
  # pictures on the graphics card with a filter that reads only 4 pixels of the
  # picture for each pixel on the screen, so a picture much larger than the
  # screen looks soft and grainy. ImageMagick's Lanczos filter reads every pixel
  # instead. Each step of the command:
  #   -colorspace RGB, then sRGB  shrinks in linear light, so dark edges do not
  #                               spread into bright areas.
  #   -resize WxH^                shrinks until the picture covers the screen.
  #   -level B%,100%              turns every gray at or below `blackPoint`
  #                               into black, for darker blacks.
  #   -unsharp                    sharpens fine detail a little, because the
  #                               picture is slightly soft even at full size.
  #   -gravity center -extent     cuts the overflow evenly from both sides.
  #
  # `runCommand name { ... } script` builds a file named `name` by running
  # `script`. `$out` is where the script writes the result. `${...}` inserts
  # the picture's path, the ImageMagick program's path, and the numbers above.
  # `toString` turns a number into text.
  fitToScreen = name: picture:
    let
      size = "${toString screen.width}x${toString screen.height}";
    in
    pkgs.runCommand "${name}-${size}.jpg" { } ''
      ${pkgs.imagemagick}/bin/magick ${picture} \
        -colorspace RGB -filter Lanczos -resize ${size}^ -colorspace sRGB \
        -level ${toString blackPoint}%,100% \
        -unsharp 0x0.8+0.8+0.01 \
        -gravity center -extent ${size} \
        -quality 95 $out
    '';

  # The chosen wallpaper, shrunk to the screen size. This is what you see.
  onScreen = fitToScreen name picture;
in
{
  # The wallpaper picture, already the size of the screen. Stylix passes it to
  # the programs it themes: wpaperd below, and swaylock in lock.nix, which shows
  # it on the lock screen. The colors stay the ones set in theme.nix, because
  # base16Scheme is set there.
  stylix.image = onScreen;

  # Fills each monitor with the picture and keeps its proportions. Parts that do
  # not fit the screen are cut off. The picture already matches the screen, so
  # nothing is cut off on this monitor.
  stylix.imageScalingMode = "fill";

  # wpaperd draws the wallpaper. It runs as a systemd user service that starts
  # with the niri session. Stylix writes its settings from `stylix.image`.
  services.wpaperd.enable = true;
}
