# Checks that `nix flake check` runs before a rebuild. They catch a broken niri
# config or Quickshell file while it is still a build error, instead of a login
# screen or desktop that does not start after the reboot. flake.nix loads this
# file as a flake-parts module, next to modules/machines.nix.
#
# `{ inputs, ... }:` makes this file a function. `inputs` holds every input of
# the flake, and `inputs.self` is this flake's own outputs. The `...` ignores the
# other arguments that flake-parts passes in.
{ inputs, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # A set of packages built for x86_64-linux. `legacyPackages` is the package set
  # that nixpkgs exposes for each system. The checks below use the host's own
  # packages where it matters, so the versions match the system.
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  # The NixOS settings of the host `nixos`, and the Home Manager settings of its
  # user `chrismg`. `inputs.self.nixosConfigurations.nixos.config` reads them from
  # the flake's outputs.
  host = inputs.self.nixosConfigurations.nixos.config;
  user = host.home-manager.users.chrismg;

  # Runs `niri validate` on a config file. niri stops with an error when the file
  # is wrong. The check is an empty file, `touch $out`, which Nix only writes when
  # the command before it succeeded.
  niriCheck = name: config: pkgs.runCommand name { } ''
    ${host.programs.niri.package}/bin/niri validate -c ${config}
    touch $out
  '';

  # Runs `qmllint` over every .qml file in a folder. qmllint exits with an error
  # on a syntax error, and the check fails then. Its warnings are printed in the
  # build log but do not fail the check, because qmllint cannot see every type
  # that Quickshell provides. `-I` adds a folder to the places qmllint looks for
  # imports, here Quickshell's and Qt's QML modules.
  qmlCheck = name: folder: quickshell: pkgs.runCommand name { } ''
    ${pkgs.kdePackages.qtdeclarative}/bin/qmllint \
      -I ${quickshell}/lib/qt-6/qml \
      -I ${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml \
      ${folder}/*.qml
    touch $out
  '';
in
{
  flake.checks.x86_64-linux = {
    # The desktop's niri settings, written by Home Manager.
    niri-user-config = niriCheck "niri-user-config" user.xdg.configFile."niri/config.kdl".source;

    # The login screen's niri settings, with the paths already filled in.
    niri-greeter-config = niriCheck "niri-greeter-config" host.system.build.greeterNiriConfig;

    # Every file of the desktop's Quickshell bar.
    quickshell-bar-qml = qmlCheck "quickshell-bar-qml" user.xdg.configFile."quickshell/chrismg".source
      user.programs.quickshell.package;

    # Every file of the login screen's Quickshell config.
    quickshell-greeter-qml = qmlCheck "quickshell-greeter-qml" host.system.build.greeterQuickshell
      host.system.build.greeterQuickshellPackage;
  };
}
