# The wallpaper pictures in this folder, by name. Any Home Manager module can
# load this file to pick one. See users/chrismg/wallpaper.nix for an example.
#
# This file is not a module, and machines.nix does not load it. A module loads it
# with `import`, which reads a .nix file and returns its value. Here the value is
# a set that maps a name to a picture.
#
# A path written without quotes, such as `./wallhaven-oglrv9.jpg`, is relative to
# this file. When a setting uses it, Nix copies only that picture into the store.
{
  # A photo of a snow-covered mountain peak in sunlight, with shadowed brown
  # slopes in front and a dark gray sky, from wallhaven.cc.
  wallhaven-oglrv9 = ./wallhaven-oglrv9.jpg;

  # A black and white drawing of a jagged, snowy mountain peak with clouds at its
  # foot, in the lower right of a black background, generated with GPT. It has no
  # wallhaven ID, so it is named after its title, "Monochrome Mountain in the
  # Void". This copy was upscaled to 3344x1882 with waifu2x. It matches the black
  # monochrome scheme.
  monochrome-mountain-in-the-void = ./monochrome-mountain-in-the-void.png;
}
