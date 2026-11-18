# nh, the "Nix helper", for NixOS hosts. Loaded because this file sits in
# features/nixos/.
#
# nh wraps the usual commands. `nh os switch .` runs the same build as
# `sudo nixos-rebuild switch --flake .#<host>`, but it shows a live build tree,
# lists the packages that changed before it activates, and asks for the sudo
# password only for the activation step.
#
# `_:` makes this file a function. `_` is a name for an argument the file does
# not use. Nix passes in a set of arguments, such as `pkgs` and `config`, and
# this file needs none of them.
_:

{
  programs.nh = {
    # Installs the `nh` command for every user.
    enable = true;

    # Deletes old generations and every store path nothing uses anymore. Each
    # generation keeps its own kernel and initrd on the small EFI boot partition,
    # so without this the store and the boot partition keep growing.
    # This replaces `nix.gc`. nh's cleaner also removes the leftover `result`
    # links and direnv caches that point into the store, which `nix.gc` keeps.
    clean = {
      enable = true;
      # A systemd calendar time, here once a week.
      dates = "weekly";
      # `--keep-since 30d` keeps every generation from the last 30 days.
      # `--keep 5` also keeps the 5 newest, so a machine that was off for a
      # month still has a few generations to roll back to.
      extraArgs = "--keep-since 30d --keep 5";
    };
  };
}
