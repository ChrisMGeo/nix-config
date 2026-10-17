# The wallpaper pictures in this folder, by name. Any Home Manager module can
# load this file to pick one. See users/chrismg/wallpaper.nix for an example.
#
# This file is not a module, and machines.nix does not load it. A module loads it
# with `import`, which reads a .nix file and returns its value. Here the value is
# a set that maps a name to a picture.
#
# A path written without quotes, such as `./wallhaven-5yzd29.png`, is relative to
# this file. When a setting uses it, Nix copies only that picture into the store.
{
  # White cherry blossoms on black, from wallhaven.cc. It matches the black
  # monochrome color scheme in themes/black-monochrome.nix.
  wallhaven-5yzd29 = ./wallhaven-5yzd29.png;

  # A photo of a pink cherry blossom branch on black, from wallhaven.cc.
  wallhaven-gwd987 = ./wallhaven-gwd987.jpg;

  # A crowned knight in armor and a red cloak raising a sword, at the right
  # edge of a black background, from wallhaven.cc.
  wallhaven-d88253 = ./wallhaven-d88253.png;

  # A photo of a snow-covered mountain peak in sunlight, with shadowed brown
  # slopes in front and a dark gray sky, from wallhaven.cc.
  wallhaven-oglrv9 = ./wallhaven-oglrv9.jpg;

  # A stylized black and white portrait of a woman with her head tilted back,
  # on the right half of a black background, from wallhaven.cc. This copy was
  # upscaled to 3840x2160 with waifu2x. It matches the black monochrome scheme.
  wallhaven-1q2kd9 = ./wallhaven-1q2kd9.png;

  # A black and white drawing of a dark figure standing in rippling water and
  # looking up at planets and stars in a black sky, from wallhaven.cc. This copy
  # was upscaled to 3840x2160 with waifu2x. It matches the black monochrome scheme.
  wallhaven-3kxgm9 = ./wallhaven-3kxgm9.png;

  # A black and white drawing of a jagged, snowy mountain peak with clouds at its
  # foot, in the lower right of a black background, generated with GPT. It has no
  # wallhaven ID, so it is named after its title, "Monochrome Mountain in the
  # Void". This copy was upscaled to 3344x1882 with waifu2x. It matches the black
  # monochrome scheme.
  monochrome-mountain-in-the-void = ./monochrome-mountain-in-the-void.png;
}
