# Account settings for every user folder on the machine reatan-x7-00. Loaded for
# every NixOS host on this machine.
#
# `{ config, lib, pkgs, ... }:` makes this file a function. `config` is the whole
# system's final settings, `lib` is the nixpkgs helper library, and `pkgs` is the
# package set.
{ config, lib, pkgs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The full name shown on the login screen and in account settings, keyed by the
  # user folder's name. A folder with no entry gets an empty name.
  fullNames = {
    chrismg = "Chris Mathew George";
  };
in
{
  # Installs zsh system-wide and adds it to the list of allowed login shells.
  # The user's zsh settings live in Home Manager, in users/chrismg/shell.nix.
  programs.zsh.enable = true;

  # machines.nix already creates a normal login account for each user folder.
  # This block adds details to each of those accounts.
  #
  # `lib.mapAttrs` runs a function on every entry of a set and returns a set with
  # the same names. `config.home-manager.users` has one entry per user folder, so
  # the accounts are set up without naming any user here. `name: _:` takes the
  # entry's name and ignores its value.
  users.users = lib.mapAttrs (name: _: {
    # `fullNames.${name} or ""` reads the entry for this user, or uses "" when
    # there is none. `or` is the fallback when a name is missing from a set.
    description = fullNames.${name} or "";

    # Groups the user belongs to.
    #   networkmanager  Manages network connections without an admin password.
    #   wheel           May run commands as the administrator with `sudo`.
    extraGroups = [ "networkmanager" "wheel" ];

    # The shell that a terminal or a login opens. zsh replaces the default, bash.
    shell = pkgs.zsh;
  }) config.home-manager.users;
}
