{ inputs, ... }:

let
  nixlib = inputs.nixpkgs.lib;

  nixFilesIn = dir:
    nixlib.mapAttrsToList
      (name: _: dir + "/${name}")
      (nixlib.filterAttrs
        (name: _: nixlib.hasSuffix ".nix" name)
        (builtins.readDir dir));

  subDirs = dir:
    nixlib.mapAttrsToList
      (name: _: name)
      (nixlib.filterAttrs
        (name: type: type == "directory" && !nixlib.hasPrefix "." name)
        (builtins.readDir dir));

  subDirsIf = dir: if builtins.pathExists dir then subDirs dir else [ ];

  features = nixFilesIn ./features;

  mkHost = machineDir: machineModules: hostName:
    let
      hostDir = machineDir + "/hosts/${hostName}";
      usersDir = hostDir + "/users";
      userModules = userName: {
        name = userName;
        value.imports = nixFilesIn (usersDir + "/${userName}");
      };
    in
    nixlib.nameValuePair hostName (inputs.nixpkgs.lib.nixosSystem {
      modules =
        features
        ++ machineModules
        ++ nixFilesIn hostDir
        ++ [
          inputs.home-manager.nixosModules.home-manager
          {
            nixpkgs.hostPlatform = nixlib.mkDefault "x86_64-linux";
            networking.hostName = nixlib.mkDefault hostName;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users = builtins.listToAttrs
              (map userModules (subDirsIf usersDir));
          }
        ];
    });

  mkMachine = machineName: _:
    let
      machineDir = ./machines + "/${machineName}";
      machineModules = nixFilesIn machineDir;
    in
    map (mkHost machineDir machineModules) (subDirsIf (machineDir + "/hosts"));
in
{
  flake.nixosConfigurations = builtins.listToAttrs
    (nixlib.concatLists
      (nixlib.mapAttrsToList mkMachine
        (nixlib.filterAttrs
          (name: type: type == "directory" && !nixlib.hasPrefix "." name)
          (builtins.readDir ./machines))));
}
