{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in

{
  home.packages = [
    inputs.nixpkgs-unstable.legacyPackages.${system}.codex
    inputs.nixpkgs-unstable.legacyPackages.${system}.opencode
    inputs.nixpkgs-unstable.legacyPackages.${system}.brave
  ];
}
