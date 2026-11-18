# The graphical desktop for NixOS hosts on the machine reatan-x7-00.
# niri is the desktop. It is a Wayland compositor that places windows in columns
# on a strip that scrolls sideways. The login screen that starts it is in
# greeter.nix.
#
# niri only draws and arranges windows. A bar, a launcher, and notifications are
# separate programs, set up per user in Home Manager.
#
# `{ lib, pkgs, unstable, ... }:` makes this file a function. `lib` is the
# nixpkgs helper library. `pkgs` is the package set. `unstable` is the
# nixpkgs-unstable package set, passed in by machines.nix.
{
  lib,
  pkgs,
  unstable,
  ...
}:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # niri from its main branch, pinned to one commit. niri 26.04, the newest
  # release, cannot run a key binding when a key is released, or bind Mod on
  # its own. The commit includes niri PR #3621, which adds both, so the user's
  # niri.nix can open the Quickshell bar by tapping Mod.
  #
  # To move the pin, change `rev` to a newer commit and `date` to its date, set
  # both hashes to `lib.fakeHash`, and rebuild. The errors print the right
  # hashes.
  pinnedRev = "689c1e914a5af782a476e433b79c15554bf5a312";
  pinnedDate = "2026-11-15";
  # The release the pinned commit comes after.
  pinnedAfter = "26.04";

  # `overrideAttrs` builds the nixpkgs-unstable niri package with changed
  # settings. `old` holds the package's own settings, and the new set replaces
  # only the names it lists.
  pinnedNiri = unstable.niri.overrideAttrs (old: rec {
    version = "${pinnedAfter}-unstable-${pinnedDate}";
    src = pkgs.fetchFromGitHub {
      owner = "niri-wm";
      repo = "niri";
      rev = pinnedRev;
      hash = "sha256-13a2sg+XKWFg+c2jCNTnso+Qbuihy6YHK2awm54VLrc=";
    };
    # The Rust libraries niri needs, downloaded ahead of the build, which has no
    # network. They change with the source, so they have their own hash.
    # `inherit src;` is short for `src = src;`, the source above. `rec` on the
    # set lets it refer to its own `src`.
    cargoDeps = unstable.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "niri-${version}";
      hash = "sha256-rLVTigIUf8rxn25bVdjVyOqPPjBq8KpKINoXQ/gFYxI=";
    };
    # `niri --version` names the commit instead of "Nixpkgs".
    env = old.env // {
      NIRI_BUILD_COMMIT = builtins.substring 0 7 pinnedRev;
    };
    # The package's install check expects `niri --version` to print the version
    # above, which a build from main does not.
    doInstallCheck = false;
  });

  # niri releases are named by year and month, such as 26.04, and are cut from
  # the main branch. No release came out between 26.04 and the pinned commit,
  # so any release newer than 26.04 comes after the commit and includes it.
  # Patch releases such as 26.04.1 are not newer here, because only the year
  # and month are compared. `majorMinor` turns "26.04.1" into "26.04".
  releaseHasPin = lib.versionOlder pinnedAfter (lib.versions.majorMinor unstable.niri.version);
in
{
  # Installs niri and adds it as a session. The nixpkgs module also turns on the
  # GNOME keyring for saved passwords and the screen sharing portals.
  programs.niri.enable = true;
  # The pinned build from main, until nixpkgs-unstable has a niri release that
  # includes it. After that, the released package is used without any change
  # here, and the pin above can be deleted.
  programs.niri.package = if releaseHasPin then unstable.niri else pinnedNiri;

  environment.systemPackages = [
    # Lets older X11 programs run under niri. niri starts it on demand when it
    # finds it on the PATH.
    pkgs.xwayland-satellite
  ];

  # Soteria shows the password prompt when a program asks for administrator
  # rights. GNOME had its own prompt, but niri does not.
  security.soteria.enable = true;

  # Lets swaylock, the lock screen, check the user's password. Without this PAM
  # entry swaylock cannot unlock the session. The niri module already adds it,
  # but the lock screen depends on it, so it is set here on purpose.
  security.pam.services.swaylock = { };

  # Installs gpu-screen-recorder, which records the screen with the graphics
  # card's video encoder. The Vicinae extension for it is in the user's
  # vicinae.nix. This option also adds a helper that may read the screen
  # directly, so recording a monitor does not ask for permission each time.
  programs.gpu-screen-recorder.enable = true;

  # dconf stores settings for GTK programs. Home Manager writes the GTK theme
  # there, so it must exist without GNOME.
  programs.dconf.enable = true;

  # gvfs is the virtual file system behind the file manager. Nautilus needs it
  # for the Trash and for network locations. GNOME used to turn it on, and niri
  # does not, so Nautilus failed with "trash locations are not supported".
  services.gvfs.enable = true;

  # udisks2 mounts removable drives such as USB sticks for the file manager.
  # Without it, plugging in a drive does nothing.
  services.udisks2.enable = true;
}
