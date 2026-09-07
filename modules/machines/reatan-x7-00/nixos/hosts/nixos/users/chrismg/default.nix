{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in

{
  home.packages = [
    inputs.codex-cli-nix.packages.${system}.default
    inputs.nixpkgs-unstable.legacyPackages.${system}.opencode
    inputs.nixpkgs-unstable.legacyPackages.${system}.brave
  ];
}
