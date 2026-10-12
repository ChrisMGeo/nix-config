# The kitty terminal for the user `chrismg` on the host `nixos`. Loaded by
# machines.nix as a Home Manager module. Stylix sets kitty's colors and font.
# See theme.nix.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  programs.kitty = {
    # Installs kitty and writes ~/.config/kitty/kitty.conf.
    enable = true;

    # Shell integration is left at the Home Manager default, "no-rc". The
    # nixpkgs build of kitty also defaults to "no-rc", so kitty never loads the
    # integration on its own. Home Manager loads it from ~/.zshrc instead.
    # Without it, kitty cannot tell when zsh is idle at a prompt, and it asks
    # for confirmation every time a window closes.

    settings = {
      # No title bar. The tab bar below shows the tabs instead.
      hide_window_decorations = "yes";
      # How many lines of output kitty keeps for scrolling back.
      scrollback_lines = 10000;
      # Space around the tab bar, in points. Vertical first, then horizontal.
      tab_bar_margin_height = "4.0 0.0";
      tab_bar_margin_width = 6.0;
      # Show the tab bar even when only one tab is open.
      tab_bar_min_tabs = 1;
      # "custom" draws tabs with the tab_bar.py file below.
      tab_bar_style = "custom";
    };

    # kitty uses Ctrl+Shift+Left and Ctrl+Shift+Right to switch tabs. An empty
    # action removes those shortcuts, so the keys go to zsh, which uses them
    # to select a word at a time. See shell.nix. Ctrl+Tab and Ctrl+Shift+Tab
    # still switch tabs.
    keybindings = {
      "ctrl+shift+left" = "";
      "ctrl+shift+right" = "";
    };
  };

  # The custom tab bar, written in Python. It draws each tab as a separate
  # rounded capsule. kitty loads it because tab_bar_style is "custom". `source`
  # links the file from kitty/tab_bar.py in this folder.
  xdg.configFile."kitty/tab_bar.py".source = ./kitty/tab_bar.py;
}
