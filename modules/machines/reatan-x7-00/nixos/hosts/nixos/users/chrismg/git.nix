# Git, the delta diff viewer, and the GitHub CLI for the user `chrismg` on the
# host `nixos`. Loaded by machines.nix as a Home Manager module.
#
# Home Manager writes the git settings to ~/.config/git/config. Git reads that
# file as well as ~/.gitconfig, so do not create a ~/.gitconfig by hand, or its
# values will mix with these.
#
# `{ config, ... }:` makes this file a function. `config` is this user's
# finished Home Manager settings, used below to find the home folder. The `...`
# ignores the other arguments.
{ config, ... }:

# `let ... in` defines local names that exist only in the set after `in`.
let
  # The public half of ~/.ssh/id_ed25519, the key that signs commits. A public
  # key is safe to store in the repository. If you replace the key, paste the
  # new ~/.ssh/id_ed25519.pub here and add it to GitHub as a signing key.
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILpnFLG/ccTSX56ENjwHqxOov9sPxQ2CF3WwR35G6UrG";

  email = "chrismathew98@gmail.com";
in

{
  programs.git = {
    enable = true;

    # Signs every commit and tag with the SSH key instead of a GPG key. GitHub
    # shows signed commits as Verified once the same public key is added under
    # Settings, SSH and GPG keys, as a key of type "Signing Key".
    signing = {
      format = "ssh";
      # The private key file. Git passes it to ssh-keygen, which reads it.
      # `${...}` inserts a value into a string.
      key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      signByDefault = true;
    };

    # Every value here becomes a line in ~/.config/git/config. A set such as
    # `init.defaultBranch` becomes the `[init]` section with `defaultBranch`.
    settings = {
      # The name and email address on every commit.
      user = {
        name = "Chris George";
        # `inherit email;` is short for `email = email;`, the name from `let`.
        inherit email;
      };

      # Names the first branch of a new repository `main`. Setting any value
      # also stops the hint git prints on `git init` about `master`.
      init.defaultBranch = "main";

      pull = {
        # `git pull` replays your local commits on top of the remote ones,
        # instead of adding a "Merge branch" commit.
        rebase = true;
      };

      rebase = {
        # Stashes uncommitted changes before a rebase and restores them after,
        # so `git pull` works with a dirty working tree.
        autoStash = true;
      };

      push = {
        # The first `git push` of a new branch creates the branch on the remote
        # and tracks it, without `-u origin <branch>`.
        autoSetupRemote = true;
      };

      fetch = {
        # Removes local copies of remote branches that were deleted on the
        # remote, such as merged pull request branches.
        prune = true;
      };

      # Lists the keys that git trusts as signers, so `git log --show-signature`
      # can check your own signatures. Without it, git prints an error for
      # every signed commit. The file is written below.
      gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
    };
  };

  # One line per trusted key: the email address it signs for, then the key.
  xdg.configFile."git/allowed_signers".text = "${email} ${signingKey}\n";

  # delta shows diffs with syntax highlighting and line numbers. It becomes the
  # pager for `git diff`, `git log -p`, `git show`, and `git add -p`.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      # Press n and N in the pager to jump to the next and previous file.
      navigate = true;
      # Shows the old and new line numbers beside each line.
      line-numbers = true;
    };
  };

  # The GitHub CLI, `gh`, for pull requests, issues, and repositories from the
  # terminal. Home Manager also makes git ask gh for the github.com password
  # over HTTPS, so pushing works after `gh auth login`. The login token stays
  # in ~/.config/gh/hosts.yml, which Home Manager does not touch.
  programs.gh = {
    enable = true;
    settings = {
      # Clones repositories over HTTPS, which uses the gh login above.
      git_protocol = "https";
      # `gh co 123` checks out pull request 123. Kept from the hand-written
      # config.yml that this file replaces.
      aliases.co = "pr checkout";
    };
  };

  # A hand-written ~/.config/gh/config.yml already exists. Its only changes
  # from the defaults are the two settings above. `force` replaces it, so the
  # rebuild does not stop with a "would be clobbered" error.
  xdg.configFile."gh/config.yml".force = true;
}
