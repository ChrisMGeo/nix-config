# The wallpaper pictures in this folder, by name. Any Home Manager module can
# load this file to pick one. See users/chrismg/wallpaper.nix for an example.
#
# This file is not a module, and machines.nix does not load it. A module loads it
# with `import`, which reads a .nix file and returns its value. Here the value is
# a set that maps a name to a picture.
#
# A path written without quotes, such as
# `./monochrome-mountain-in-the-void.jpg`, is relative to this file. When a
# setting uses it, Nix copies only that picture into the store.
{
  # A black and white drawing of a jagged, snowy mountain peak with clouds at its
  # foot, in the lower right of a black background, generated with GPT. It has no
  # wallhaven ID, so it is named after its title, "Monochrome Mountain in the
  # Void". It was upscaled to 3344x1882 with waifu2x. It matches the black
  # monochrome scheme.
  #
  # This copy is already edited, so nothing runs at build time. Its blacks are
  # darkened and its detail is sharpened a little. The original PNG is in git
  # history, before the commit that added this file. To redo the edit, run this
  # on the original:
  #
  #   magick original.png -level 10%,100% -unsharp 0x0.8+0.8+0.01 \
  #     -quality 95 monochrome-mountain-in-the-void.jpg
  #
  # -level 10%,100% turns every gray at or below 10% of white into black. The
  # background is nearly black with film grain up to about 8%, so this makes it
  # true black and stretches the brighter tones for more contrast. -unsharp
  # sharpens fine detail, because the picture is slightly soft.
  monochrome-mountain-in-the-void = ./monochrome-mountain-in-the-void.jpg;
}
