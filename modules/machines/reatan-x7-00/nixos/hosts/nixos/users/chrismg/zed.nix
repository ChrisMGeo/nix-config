# The Zed code editor for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module.
#
# `{ inputs, pkgs, unstable, ... }:` makes this file a function. `inputs` is the
# flake's inputs. `pkgs` is the package set. `unstable` is the nixpkgs-unstable
# package set. machines.nix passes `inputs` and `unstable` in. The `...` ignores
# the other arguments.
{
  inputs,
  pkgs,
  unstable,
  ...
}:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The Claude Code adapter for Zed's agent panel, from the llm-agents flake,
  # built for this machine's platform. `${...}` puts the platform name, such as
  # "x86_64-linux", into the attribute path. Its launcher already points at the
  # Nix-built `claude` program from the same flake, so it needs nothing else.
  claude-agent-acp = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-agent-acp;
in

{
  programs.zed-editor = {
    # Installs Zed and manages its settings, extensions, and themes.
    enable = true;

    # Zed from nixpkgs-unstable. Zed releases every week, so the stable set
    # falls behind quickly.
    package = unstable.zed-editor;

    # Extensions Zed installs the next time it starts, by their id in
    # github.com/zed-industries/extensions. Home Manager writes them into
    # settings.json as `auto_install_extensions`. Zed downloads them itself, so
    # they are not pinned by flake.lock. Removing a name here does not uninstall
    # the extension. Uninstall it in Zed's extensions page too.
    extensions = [
      # Language support. "nix" uses nixd from nix-tools.nix. The
      # `languages.Nix` setting below turns off its second server, nil.
      "nix"
      "html"

      # Color themes. "base16" has Base16 Black Metal, the dark theme set below.
      "base16"
    ];

    # Zed may still write to settings.json, for example when a setting is
    # changed in its settings page. On every rebuild, Home Manager merges the
    # settings below into the file. A key set below replaces the value in the
    # file, and keys only in the file are kept.
    mutableUserSettings = true;

    # Written into ~/.config/zed/settings.json. The names match Zed's own
    # settings. See https://zed.dev/docs/configuring-zed.
    userSettings = {
      # Text size, in pixels, for menus and panels, and for the code itself.
      ui_font_size = 16;
      buffer_font_size = 15;

      # The color theme. `mode = "dark"` always uses the dark theme, instead of
      # following the system's light or dark preference.
      theme = {
        mode = "dark";
        light = "One Light";
        dark = "Base16 Black Metal";
      };

      # Zed's own file icons, for both light and dark mode.
      icon_theme = {
        mode = "light";
        light = "Zed (Default)";
        dark = "Zed (Default)";
      };

      # The Nix extension starts two language servers by default, nil and nixd.
      # Only nixd is installed, by nix-tools.nix, and the extension does not
      # download nil, so Zed would show "nil must be installed manually". The
      # list runs nixd, and "!nil" turns nil off.
      languages.Nix.language_servers = [
        "nixd"
        "!nil"
      ];

      # Color each tab's file name by its git status, such as changed or new.
      tabs.git_status = true;

      # Show changed lines in the left margin only for files git tracks.
      git.git_gutter = "tracked_files";

      # The git panel.
      git_panel = {
        # Split the list into staged and unstaged changes.
        group_by = "staging";
        # Show the changes inside new files instead of hiding them.
        collapse_untracked_diff = false;
        # The branch name for a new repository that has no branch yet.
        fallback_branch_name = "main";
        # Show a file's status as an icon, not as a colored name.
        status_style = "icon";
        # Show files in their folders instead of as one flat list.
        tree_view = true;
      };

      # Coding agents that Zed's agent panel can start. "claude-acp" is the name
      # Zed gives Claude Code. With "registry", Zed downloads a generic Linux
      # build of the adapter, which NixOS cannot run (exit status 127). "custom"
      # runs the Nix-built adapter from the path below instead. Keeping the same
      # name replaces the downloaded one in Zed's agent list.
      agent_servers.claude-acp = {
        type = "custom";
        command = "${claude-agent-acp}/bin/claude-agent-acp";
      };
    };
  };

  # Stylix themes Zed automatically once Home Manager manages it, which would
  # replace the theme and fonts above. Zed keeps its own look for now.
  stylix.targets.zed.enable = false;
}
