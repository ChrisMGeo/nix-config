# Docker container runtime for NixOS hosts on the machine reatan-x7-00. Loaded
# for every NixOS host on this machine.
#
# `{ config, lib, ... }:` makes this file a function. `config` is the whole
# system's final settings, and `lib` is the nixpkgs helper library.
{
  config,
  lib,
  ...
}:

{
  virtualisation.docker = {
    # Runs the Docker daemon as a system service and installs the `docker`
    # command, which includes `docker compose` and `docker buildx`.
    enable = true;

    # Starts the daemon the first time something talks to its socket, not at
    # boot. This keeps boot fast when no container is needed.
    enableOnBoot = false;

    # Deletes stopped containers, unused networks, and dangling images once a
    # week, so old builds do not fill the disk. Named volumes are kept, because
    # they can hold data that is not stored anywhere else.
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Adds every user folder's account to the `docker` group, so `docker` works
  # without `sudo`. Members of this group can control the daemon, which runs as
  # root, so this is the same trust level as the `wheel` group in admin.nix.
  #
  # `lib.mapAttrs` runs a function on every entry of a set and returns a set
  # with the same names. `config.home-manager.users` has one entry per user
  # folder. `_: _:` ignores both the entry's name and its value. NixOS merges
  # this `extraGroups` list with the one in admin.nix.
  users.users = lib.mapAttrs (_: _: {
    extraGroups = [ "docker" ];
  }) config.home-manager.users;
}
