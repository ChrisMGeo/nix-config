# Account settings for the user `chrismg`. Loaded for every NixOS host on the
# machine reatan-x7-00.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # machines.nix already creates a normal login account for each user folder.
  # This block adds details to that account.
  users.users.chrismg = {
    # The full name shown on the login screen and in account settings.
    description = "Chris Mathew George";

    # Groups the user belongs to.
    #   networkmanager  Manages network connections without an admin password.
    #   wheel           May run commands as the administrator with `sudo`.
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
