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
}
