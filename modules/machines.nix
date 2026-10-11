# Finds machines, hosts, and users from the folder layout, then builds every NixOS
# and darwin system this flake exposes.
#
# You rarely edit this file. To add a machine, host, or user, create folders and
# files in the right place. The README explains the layout.
#
# Nix idioms used below.
#   let ... in   Defines local helper values. They exist only between `let` and `in`.
#   name: value  A function with one argument. `a: b: ...` takes two arguments, one at a time.
#   nixlib       A short name for nixpkgs' library of helper functions, such as `filterAttrs`.
#   ${name}      Inserts the value of `name` into a string.
#
# `{ inputs, ... }:` makes this file a function. Nix passes in `inputs`, the flake
# inputs, and ignores any other arguments because of the `...`.
{ inputs, ... }:

let
  # Named `nixlib` so it does not look like the `lib` argument that module files receive.
  nixlib = inputs.nixpkgs.lib;

  # Returns the `.nix` files directly inside `dir`, as full paths.
  # Subfolders are skipped. The files come back in alphabetical order.
  nixFilesIn = dir:
    nixlib.mapAttrsToList
      # `dir + "/${name}"` joins the folder path and the file name into one path.
      (name: _: dir + "/${name}")
      (nixlib.filterAttrs
        # `_` marks a value we do not use. `hasSuffix` keeps names ending in ".nix".
        (name: _: nixlib.hasSuffix ".nix" name)
        # `builtins.readDir` returns a set that maps each name to its type,
        # such as "regular" for a file or "directory" for a folder.
        (builtins.readDir dir));

  # Returns the names of the folders directly inside `dir`. Hidden folders, whose
  # names start with ".", are skipped.
  subDirs = dir:
    nixlib.mapAttrsToList
      (name: _: name)
      (nixlib.filterAttrs
        (name: type: type == "directory" && !nixlib.hasPrefix "." name)
        (builtins.readDir dir));

  # Like `subDirs`, but returns [ ] when `dir` does not exist. Lets optional
  # folders such as `users/` be missing. `[ ]` is an empty list.
  subDirsIf = dir: if builtins.pathExists dir then subDirs dir else [ ];

  # Like `nixFilesIn`, but returns [ ] when `dir` does not exist.
  nixFilesIf = dir: if builtins.pathExists dir then nixFilesIn dir else [ ];

  # Maps each platform folder name to a "class". The class decides which
  # builder function and which feature folder a host uses.
  # WSL machines run NixOS, so `wsl` maps to `nixos`. No WSL support module is
  # loaded, so a WSL host needs its own WSL setup.
  platformClass = {
    nixos = "nixos";
    wsl = "nixos";
    darwin = "darwin";
  };

  # Turns each platform folder name into { name; class; }.
  # `?` asks whether a set has an attribute. `${platform}` plugs in the name.
  # Any unknown folder name stops evaluation with an error, so a typo fails early.
  platformsOf = machineDir:
    map
      (platform:
        if platformClass ? ${platform}
        then { name = platform; class = platformClass.${platform}; }
        else throw "unknown platform directory '${platform}' in ${toString machineDir} (expected darwin, nixos or wsl)")
      (subDirs machineDir);

  # The shared feature files for one class.
  # `./features` is relative to this file, so it means modules/features.
  # Files directly in features/ load for every class. Files in features/<class>/
  # load only for that class. `++` joins two lists.
  features = class: nixFilesIn ./features ++ nixFilesIf (./features + "/${class}");

  # Builds one host.
  #   class      "nixos" or "darwin".
  #   modules    The machine and platform files this host shares with its siblings.
  #   platformDir  The platform folder, such as machines/<machine>/nixos.
  #   hostName   The host's folder name, such as "nixos".
  mkHost = class: modules: platformDir: hostName:
    let
      # Files that belong to this one host.
      hostDir = platformDir + "/hosts/${hostName}";
      # One folder per user lives under hosts/<host>/users/.
      usersDir = hostDir + "/users";
      userNames = subDirsIf usersDir;

      # Builds the Home Manager settings for one user. Home Manager manages a
      # user's own files and packages, such as ~/.config. It is separate from
      # NixOS, which manages the whole system.
      userModules = userName: {
        name = userName;
        value = {
          # Every .nix file in users/<name>/ is a Home Manager module.
          imports = nixFilesIn (usersDir + "/${userName}");
          # The login name and home folder. mkDefault lets another file replace them.
          home.username = nixlib.mkDefault userName;
          home.homeDirectory = nixlib.mkDefault
            (if class == "darwin" then "/Users/${userName}" else "/home/${userName}");
          # The Home Manager state version. Do not change it. See the README.
          home.stateVersion = nixlib.mkDefault "26.05";
          # Installs the `home-manager` command for this user.
          programs.home-manager.enable = nixlib.mkDefault true;
        };
      };

      # The function that builds the system. nix-darwin for macOS, NixOS for Linux.
      buildSystem = if class == "darwin"
        then inputs.darwin.lib.darwinSystem
        else inputs.nixpkgs.lib.nixosSystem;

      # The Home Manager module that matches the platform.
      homeManagerModule = if class == "darwin"
        then inputs.home-manager.darwinModules.home-manager
        else inputs.home-manager.nixosModules.home-manager;
    in
    {
      # Shorthand for `hostName = hostName; class = class;`.
      inherit hostName class;

      # The built system. Its list of modules is assembled in this order:
      #   1. Shared features, for every platform and for this class.
      #   2. Machine and platform files, passed in as `modules`.
      #   3. Host files in this host's folder.
      #   4. Home Manager, plus the settings in the list below.
      system = buildSystem {
        modules =
          features class
          ++ modules
          ++ nixFilesIn hostDir
          ++ [
            homeManagerModule

            # NixOS only. `optionalAttrs cond set` returns `set` when `cond` is true
            # and an empty set otherwise.
            (nixlib.optionalAttrs (class == "nixos") {
              system.stateVersion = nixlib.mkDefault "26.05";
              # Creates a normal login account, with a home folder, for each user folder.
              # `builtins.listToAttrs` turns a list of { name; value; } pairs into
              # one set keyed by name.
              users.users = builtins.listToAttrs
                (map (userName: {
                  name = userName;
                  value.isNormalUser = nixlib.mkDefault true;
                }) userNames);
            })

            # darwin only. The state version for nix-darwin.
            (nixlib.optionalAttrs (class == "darwin") {
              system.stateVersion = nixlib.mkDefault 7;
            })

            # darwin only, and only when a user folder exists. nix-darwin uses
            # `primaryUser` for settings that belong to one account. `head` takes
            # the first name from the list.
            (nixlib.optionalAttrs (class == "darwin" && userNames != [ ]) {
              system.primaryUser = nixlib.mkDefault (nixlib.head userNames);
            })

            # Settings shared by every host. Written as a function so it can use
            # `pkgs`, the host's package set, which NixOS passes to every module.
            ({ pkgs, ... }: {
              # The CPU and operating system the host runs on.
              nixpkgs.hostPlatform = nixlib.mkDefault
                (if class == "darwin" then "aarch64-darwin" else "x86_64-linux");

              # The machine's network name, taken from the host folder name.
              networking.hostName = nixlib.mkDefault hostName;

              # Home Manager uses the system's nixpkgs instead of its own copy.
              home-manager.useGlobalPkgs = true;
              # Installs each user's packages under /etc/profiles/per-user/<name>.
              home-manager.useUserPackages = true;
              # When Home Manager would replace a file it did not create, such as
              # an existing ~/.zshrc, it runs this script on the old file instead
              # of stopping with an error. Home Manager adds the file's path as the
              # last argument, `$1`. The script renames the file to
              # <name>.hm-backup. `--backup=numbered` keeps an older backup as
              # <name>.hm-backup.~1~, ~2~, and so on, instead of failing.
              home-manager.backupCommand = pkgs.writeShellScript "home-manager-backup" ''
                exec ${pkgs.coreutils}/bin/mv --backup=numbered --no-target-directory -- "$1" "$1.hm-backup"
              '';
              # Makes `inputs` available as an argument in Home Manager modules.
              home-manager.extraSpecialArgs = { inherit inputs; };
              # One Home Manager configuration for each user folder.
              home-manager.users = builtins.listToAttrs (map userModules userNames);
            })
          ];
      };
    };

  # Builds every host in one platform folder, such as machines/<machine>/nixos.
  #   machineModules  The .nix files directly in the machine folder.
  #   machineDir      The machine folder.
  #   platform        One entry from `platformsOf`.
  # Passing only some arguments returns a function that still waits for the last
  # one. `map` supplies one host folder name at a time.
  mkPlatform = machineModules: machineDir: platform:
    let
      platformDir = machineDir + "/${platform.name}";
      # Shared files for every host on this platform. Machine files come first.
      platformModules = machineModules ++ nixFilesIn platformDir;
    in
    map (mkHost platform.class platformModules platformDir)
      (subDirsIf (platformDir + "/hosts"));

  # Builds every platform in one machine folder. The `_` argument is the folder
  # type from `mapAttrsToList`, which this function does not need.
  mkMachine = machineName: _:
    let
      machineDir = ./machines + "/${machineName}";
      # .nix files directly in the machine folder. Every host on this machine loads them.
      machineModules = nixFilesIn machineDir;
    in
    # `concatLists` flattens a list of lists into one list.
    nixlib.concatLists (map (mkPlatform machineModules machineDir) (platformsOf machineDir));

  # Every host on every machine, as one flat list. Hidden folders are skipped.
  systems = nixlib.concatLists
    (nixlib.mapAttrsToList mkMachine
      (nixlib.filterAttrs
        (name: type: type == "directory" && !nixlib.hasPrefix "." name)
        (builtins.readDir ./machines)));

  # Keeps the hosts for one class and returns them as a set keyed by host name,
  # such as { nixos = <system>; }.
  # If two hosts in the same class share a name, the first one wins and the
  # second is dropped without a warning.
  systemsOf = class:
    builtins.listToAttrs
      (map (s: nixlib.nameValuePair s.hostName s.system)
        (nixlib.filter (s: s.class == class) systems));
in
{
  # This module sets flake outputs. `nixos-rebuild --flake .#<name>` reads
  # flake.nixosConfigurations.<name>.
  flake.nixosConfigurations = systemsOf "nixos";

  # `darwin-rebuild --flake .#<name>` reads flake.darwinConfigurations.<name>.
  # No macOS machine is defined yet.
  flake.darwinConfigurations = systemsOf "darwin";
}
