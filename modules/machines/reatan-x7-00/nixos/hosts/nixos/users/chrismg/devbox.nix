# Devbox and direnv for the user `chrismg` on the host `nixos`, so each project
# can have its own tools without installing them for the whole user. Loaded by
# machines.nix as a Home Manager module.
#
# Devbox reads a `devbox.json` in a project folder and installs the packages it
# lists from nixpkgs into that project only. direnv then loads them into the
# shell when you `cd` into the folder and removes them when you leave.
#
# Start a project with:
#   devbox init                 Writes an empty devbox.json.
#   devbox add python@3.12      Adds a package to it.
#   devbox generate direnv      Writes an .envrc, then runs `direnv allow`.
# Without direnv, `devbox shell` opens a shell with the packages instead.
#
# `{ unstable, ... }:` makes this file a function. `unstable` is the
# nixpkgs-unstable package set, which machines.nix passes in. The `...` ignores
# the other arguments.
{ unstable, ... }:

{
  # Devbox from nixpkgs-unstable. Devbox releases often, and the stable set
  # falls behind by a minor version or more.
  home.packages = [ unstable.devbox ];

  programs.direnv = {
    # Installs direnv and adds its hook to ~/.zshrc, because zsh is enabled in
    # shell.nix. The hook runs on every prompt and loads or unloads a folder's
    # .envrc. direnv only runs an .envrc after `direnv allow` in that folder.
    enable = true;

    # nix-direnv, a faster, cached `use flake` and `use nix` for .envrc files.
    # Devbox does not need it, but projects with a flake.nix instead of a
    # devbox.json do. Its cache also keeps the project's packages from being
    # deleted by garbage collection.
    nix-direnv.enable = true;
  };
}
