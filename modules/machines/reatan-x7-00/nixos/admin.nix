# Account settings for the user `chrismg`. Loaded for every NixOS host on the
# machine reatan-x7-00.
#
# `{ pkgs, ... }:` makes this file a function. `pkgs` is the package set.
{ pkgs, ... }:

{
  # Installs zsh system-wide and adds it to the list of allowed login shells.
  # The user's zsh settings live in Home Manager, in users/chrismg/shell.nix.
  programs.zsh.enable = true;

  # machines.nix already creates a normal login account for each user folder.
  # This block adds details to that account.
  users.users.chrismg = {
    # The full name shown on the login screen and in account settings.
    description = "Chris Mathew George";

    # Groups the user belongs to.
    #   networkmanager  Manages network connections without an admin password.
    #   wheel           May run commands as the administrator with `sudo`.
    extraGroups = [ "networkmanager" "wheel" ];

    # The shell that a terminal or a login opens. zsh replaces the default, bash.
    shell = pkgs.zsh;
  };
}
