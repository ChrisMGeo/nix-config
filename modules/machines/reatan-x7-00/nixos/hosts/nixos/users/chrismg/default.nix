{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  agents = inputs.llm-agents.packages.${system};
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in

{
  home.packages = [
    agents.codex
    agents.opencode
    agents.claude-code
    pkgs.brave
    unstable.zed-editor
  ];
}
