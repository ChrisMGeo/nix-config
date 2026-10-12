# A black and white Base16 color scheme, with gray in place of the accent
# colors. Any Home Manager module can use it with Stylix:
#
#   stylix.base16Scheme = import "${inputs.self}/themes/black-monochrome.nix";
#
# This file is not a module, and machines.nix does not load it. `import` reads
# it and returns the set below.
#
# A Base16 scheme is 16 colors, base00 to base0F, written as hex codes without
# the "#". base00 to base07 run from the background to the brightest text.
# base08 to base0F are accent colors.
{
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
}
