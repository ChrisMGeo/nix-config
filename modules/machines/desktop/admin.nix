{ ... }:

{
  users.users.chrismg = {
    isNormalUser = true;
    description = "Chris Mathew George";
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
