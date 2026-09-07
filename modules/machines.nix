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

  platformClass = {
    nixos = "nixos";
    wsl = "nixos";
    darwin = "darwin";
  };

  platformsOf = machineDir:
    map
      (platform:
        if platformClass ? ${platform}
        then { name = platform; class = platformClass.${platform}; }
        else throw "unknown platform directory '${platform}' in ${toString machineDir} (expected darwin, nixos or wsl)")
      (subDirs machineDir);

  features = nixFilesIn ./features;

  mkHost = class: modules: platformDir: hostName:
    let
      hostDir = platformDir + "/hosts/${hostName}";
      usersDir = hostDir + "/users";
      userModules = userName: {
        name = userName;
        value.imports = nixFilesIn (usersDir + "/${userName}");
      };
      buildSystem = if class == "darwin"
        then inputs.darwin.lib.darwinSystem
        else inputs.nixpkgs.lib.nixosSystem;
      homeManagerModule = if class == "darwin"
        then inputs.home-manager.darwinModules.home-manager
        else inputs.home-manager.nixosModules.home-manager;
    in
    {
      inherit hostName class;
      system = buildSystem {
        modules =
          features
          ++ modules
          ++ nixFilesIn hostDir
          ++ [
            homeManagerModule
            {
              nixpkgs.hostPlatform = nixlib.mkDefault
                (if class == "darwin" then "aarch64-darwin" else "x86_64-linux");
              networking.hostName = nixlib.mkDefault hostName;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = builtins.listToAttrs
                (map userModules (subDirsIf usersDir));
            }
          ];
      };
    };

  mkPlatform = machineModules: machineDir: platform:
    let
      platformDir = machineDir + "/${platform.name}";
      platformModules = machineModules ++ nixFilesIn platformDir;
    in
    map (mkHost platform.class platformModules platformDir)
      (subDirsIf (platformDir + "/hosts"));

  mkMachine = machineName: _:
    let
      machineDir = ./machines + "/${machineName}";
      machineModules = nixFilesIn machineDir;
    in
    nixlib.concatLists (map (mkPlatform machineModules machineDir) (platformsOf machineDir));

  systems = nixlib.concatLists
    (nixlib.mapAttrsToList mkMachine
      (nixlib.filterAttrs
        (name: type: type == "directory" && !nixlib.hasPrefix "." name)
        (builtins.readDir ./machines)));

  systemsOf = class:
    builtins.listToAttrs
      (map (s: nixlib.nameValuePair s.hostName s.system)
        (nixlib.filter (s: s.class == class) systems));
in
{
  flake.nixosConfigurations = systemsOf "nixos";
  flake.darwinConfigurations = systemsOf "darwin";
}
