# The zsh shell and the starship prompt for the user `chrismg` on the host
# `nixos`. Loaded by machines.nix as a Home Manager module. admin.nix makes zsh
# the login shell, so a terminal opens zsh.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # Writes ~/.zshrc and the other zsh startup files.
  programs.zsh = {
    enable = true;

    # Lines added to ~/.zshrc. `''...''` is a multi-line string in Nix. Inside
    # it, `''${` writes a literal `${` for zsh, because a plain `${` would be
    # read by Nix instead.
    #
    # The quoted key strings are the escape codes the terminal sends. In
    # `^[[1;5D`, the number after the semicolon names the held keys: 2 is
    # Shift, 3 is Alt, 5 is Ctrl, and 6 is Ctrl and Shift. The final letter is
    # the key: D is Left, C is Right, H is Home, and F is End.
    initContent = ''
      # zsh has no default binding for Ctrl or Alt with the arrow keys. These
      # move the cursor one word left or right.
      bindkey '^[[1;5D' backward-word
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;3D' backward-word
      bindkey '^[[1;3C' forward-word

      # Selecting text with Shift, as in a text editor. Shift with an arrow,
      # Home, or End starts a selection and extends it. Ctrl and Shift with an
      # arrow extends it by a word. While text is selected, zsh switches to a
      # separate set of key bindings named shift-select:
      #   Backspace or Delete removes the selected text.
      #   A typed character replaces the selected text.
      #   Any other key clears the selection and then does its usual job.

      # Starts a selection if none is active, then runs the movement named
      # after `shift-select::` in this widget's name.
      function shift-select::select-and-invoke() {
        if (( !REGION_ACTIVE )); then
          zle set-mark-command
          zle -K shift-select
        fi
        zle ''${WIDGET#shift-select::}
      }

      # Clears the selection and sends the pressed key to the normal bindings.
      function shift-select::deselect-and-input() {
        zle deactivate-region
        zle -K main
        zle -U "$KEYS"
      }

      # Removes the selected text.
      function shift-select::kill-region() {
        zle kill-region -w
        zle -K main
      }

      # Removes the selected text, then types the pressed key in its place.
      function shift-select::replace-and-input() {
        zle kill-region -w
        zle -K main
        zle -U "$KEYS"
      }

      for widget in backward-char forward-char backward-word forward-word \
          beginning-of-line end-of-line; do
        zle -N shift-select::$widget shift-select::select-and-invoke
      done
      zle -N shift-select::deselect-and-input
      zle -N shift-select::kill-region
      zle -N shift-select::replace-and-input

      # The bindings used while text is selected. Every control key clears
      # the selection, and every printable character replaces it.
      bindkey -N shift-select
      bindkey -M shift-select -R '^@'-'^?' shift-select::deselect-and-input
      bindkey -M shift-select -R ' '-'~' shift-select::replace-and-input
      bindkey -M shift-select '^?' shift-select::kill-region
      bindkey -M shift-select '^H' shift-select::kill-region
      bindkey -M shift-select '^[[3~' shift-select::kill-region

      # The Shift keys work both before and during a selection.
      for keymap in main shift-select; do
        bindkey -M $keymap '^[[1;2D' shift-select::backward-char
        bindkey -M $keymap '^[[1;2C' shift-select::forward-char
        bindkey -M $keymap '^[[1;6D' shift-select::backward-word
        bindkey -M $keymap '^[[1;6C' shift-select::forward-word
        bindkey -M $keymap '^[[1;2H' shift-select::beginning-of-line
        bindkey -M $keymap '^[[1;2F' shift-select::end-of-line
      done
    '';
  };

  # starship draws the prompt: the current folder, the git branch, and the exit
  # status of the last command. Home Manager adds it to ~/.zshrc because zsh is
  # enabled above.
  programs.starship.enable = true;
}
