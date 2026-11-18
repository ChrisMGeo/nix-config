# Tools for editing and inspecting Nix code, for the user `chrismg` on the host
# `nixos`. Loaded by machines.nix as a Home Manager module.
#
# `{ pkgs, ... }:` makes this file a function. `pkgs` is the package set. The
# `...` ignores the other arguments.
{ pkgs, ... }:

{
  # Packages installed for this user only, all from the stable nixpkgs set.
  # Home Manager merges this list with the one in default.nix.
  home.packages = [
    # nixd, a language server for Nix. Editors such as Zed start it to show
    # errors, completion, and go-to-definition in .nix files. It evaluates the
    # flake, so it can also complete NixOS and Home Manager option names.
    pkgs.nixd

    # nixfmt, the official Nix formatter. nixd uses it to format a file on save.
    # Run `nixfmt <file>.nix` to format one file by hand.
    pkgs.nixfmt

    # statix, a linter that finds Nix code with a simpler way to write it, such
    # as `x = x;` that could be `inherit x;`. Run `statix check .` to list them
    # and `statix fix .` to apply the fixes.
    pkgs.statix

    # deadnix, a linter that finds names that are defined but never used, such
    # as an unused function argument or `let` binding. Run `deadnix .` to list
    # them and `deadnix --edit .` to delete them.
    pkgs.deadnix

    # nix-tree, a terminal browser for what a build depends on and how much
    # space each part takes. Run `nix-tree /run/current-system` to see why the
    # running system is the size it is.
    pkgs.nix-tree
  ];
}
