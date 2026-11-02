# Makes Brave the default web browser for the user `chrismg` on the host
# `nixos`. Loaded by machines.nix as a Home Manager module. Brave itself is
# installed in default.nix.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The name of the launcher file that Brave installs in share/applications.
  # Programs look up this file to know how to start Brave.
  brave = "brave-browser.desktop";
in

{
  # Writes ~/.config/mimeapps.list, the file that tells xdg-open and other
  # programs which app opens each kind of file and link.
  xdg.mimeApps = {
    enable = true;

    # The default app for each kind. A quoted name with a slash is a file type,
    # and `x-scheme-handler/<name>` is a link that starts with `<name>:`.
    defaultApplications = {
      # Web pages and web links open in Brave. `about` and `unknown` are links
      # with no other handler, which browsers also take.
      "text/html" = brave;
      "application/xhtml+xml" = brave;
      "x-scheme-handler/http" = brave;
      "x-scheme-handler/https" = brave;
      "x-scheme-handler/about" = brave;
      "x-scheme-handler/unknown" = brave;

      # Links that sign in to or open other apps. These apps added themselves
      # to the old hand-written file, and that file is now read-only, so they
      # are listed here to keep them working.
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/t3code" = "com.t3tools.T3Code.desktop";
    };
  };

  # Replaces the hand-written ~/.config/mimeapps.list that existed before this
  # file. Without this, Home Manager stops instead of overwriting a file it did
  # not create.
  xdg.configFile."mimeapps.list".force = true;

  # Terminal programs that open a web page without xdg-open read the BROWSER
  # variable instead. `brave` is the command that the Brave package installs.
  home.sessionVariables.BROWSER = "brave";
}
