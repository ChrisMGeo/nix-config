# The zsh shell and the starship prompt for the user `chrismg` on the host
# `nixos`. Loaded by machines.nix as a Home Manager module. admin.nix makes zsh
# the login shell, so a terminal opens zsh.
#
# `{ ... }:` makes this file a function. It does not need any arguments.
{ ... }:

{
  # Writes ~/.zshrc and the other zsh startup files.
  programs.zsh.enable = true;

  # starship draws the prompt: the current folder, the git branch, and the exit
  # status of the last command. Home Manager adds it to ~/.zshrc because zsh is
  # enabled above.
  programs.starship.enable = true;
}
