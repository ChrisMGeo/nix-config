# T3 Code for the user `chrismg` on the host `nixos`, set up to run Antigravity
# through the Nix-built Antigravity CLI. Loaded by machines.nix as a Home
# Manager module.
#
# T3 Code is a desktop app for running and watching coding agents. It talks to
# Antigravity over ACP, the Agent Client Protocol, by starting `agy acp`. On its
# own, T3 Code offers to download Google's generic Linux build of that runtime,
# and otherwise looks only for a file named `agy_acp_server.par`, never `agy`.
# The download does not run on NixOS, so this file puts the Nix-built `agy` on
# T3 Code's PATH and sets T3 Code's "Binary path" setting for Antigravity to
# `agy`.
#
# `{ inputs, lib, pkgs, ... }:` makes this file a function. `inputs` is the
# flake's inputs, `lib` is the nixpkgs helper library, and `pkgs` is the
# package set. The `...` ignores the other arguments.
{
  inputs,
  lib,
  pkgs,
  ...
}:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # Packages from the llm-agents flake, built for this platform.
  # `${...}` puts a value into a name or string, here the platform name, such
  # as "x86_64-linux".
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # T3 Code with the Antigravity CLI added to the agents on its PATH. The
  # package already puts Codex, Claude Code, Cursor, Grok, and OpenCode there,
  # listed in its `providerPackages`. `.override` rebuilds a package with some
  # of its inputs changed. Only the small launcher script is rebuilt. The app
  # itself is the same build, so it still downloads from Numtide's cache.
  t3code = agents.t3code.override {
    providerPackages = agents.t3code.providerPackages ++ [ agents.antigravity-cli ];
  };

  # The desktop app, built from the T3 Code above instead of the default one.
  # `inherit t3code;` is short for `t3code = t3code;`.
  t3code-desktop = agents.t3code-desktop.override { inherit t3code; };

  # The setting below, as a jq program. It makes the "antigravity" provider
  # entry if it is missing, with the driver T3 Code needs, and sets its binary
  # path to `agy`, which T3 Code looks up on its PATH. A missing entry starts
  # turned off, as Antigravity does by default, so this does not turn it on.
  settingsFilter = ''
    .providerInstances.antigravity.driver //= "antigravity"
    | .providerInstances.antigravity.config.binaryPath = "agy"
  '';
in

{
  # The T3 Code desktop app. It opens in its own window and shows up in the
  # app launcher.
  home.packages = [ t3code-desktop ];

  # T3 Code writes its own settings to ~/.t3/userdata/settings.json, for example
  # when a setting is changed in its settings page, so Home Manager cannot own
  # the file. Instead, this script runs on every rebuild and changes only the
  # Antigravity binary path. Every other setting in the file is kept. T3 Code
  # watches the file and reads the change without a restart.
  #
  # `lib.hm.dag.entryAfter [ "writeBoundary" ]` runs the script after Home
  # Manager has written its own files. `run` skips the command in a dry run.
  # `warnEcho` prints a warning without stopping the rebuild.
  home.activation.t3codeAntigravity = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.t3/userdata/settings.json"
    run mkdir -p "$(dirname "$settings")"

    # Before T3 Code first starts, the file does not exist yet. Start from an
    # empty JSON object then.
    if [ -s "$settings" ]; then
      current="$(cat "$settings")"
    else
      current='{}'
    fi

    # Write to a temporary file in the same folder, then move it over the old
    # file in one step, so T3 Code never reads a half-written file.
    tmp="$(mktemp "$settings.XXXXXX")"
    if printf '%s' "$current" | ${lib.getExe pkgs.jq} ${lib.escapeShellArg settingsFilter} > "$tmp"; then
      run chmod 644 "$tmp"
      run mv "$tmp" "$settings"
    else
      warnEcho "Could not read $settings, so the T3 Code Antigravity path was not set."
    fi
    # Removes the temporary file after a failure or a dry run. After a move it
    # is already gone.
    rm -f "$tmp"
  '';
}
