# Global rules for the coding agents of the user `chrismg` on the host
# `nixos`. Loaded by machines.nix as a Home Manager module.
#
# Each agent reads one Markdown file of instructions from the home folder in
# every project, its global rules file. This file links the same rules,
# agent-rules/global.md, into the rules file of every installed agent, listed
# in `ruleFiles`. The links point into the Nix store, so the files are
# read-only. Change agent-rules/global.md and rebuild.
#
# `{ lib, ... }:` makes this file a function. `lib` is the nixpkgs helper
# library, and the `...` ignores the other arguments.
{ lib, ... }:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The global rules file, relative to the home folder, of each installed
  # agent. Add an entry here when you install a new agent.
  ruleFiles = {
    # Claude Code reads its user memory from this file.
    claude-code = ".claude/CLAUDE.md";
    # Codex reads this file before the AGENTS.md files of a project.
    codex = ".codex/AGENTS.md";
    # OpenCode reads this file. Without it, OpenCode falls back to
    # ~/.claude/CLAUDE.md, but its own file keeps working if Claude Code is
    # removed.
    opencode = ".config/opencode/AGENTS.md";
    # The Antigravity CLI and app read this file as their global rules.
    antigravity = ".gemini/GEMINI.md";
  };

  # The rules every agent gets. A path such as `./agent-rules/global.md` is
  # relative to this file, and Nix copies the file into the Nix store.
  rules = ./agent-rules/global.md;
in
{
  # Files Home Manager creates in the home folder. `lib.mapAttrs'` turns each
  # `agent = path;` entry of `ruleFiles` into a `path = { source = rules; };`
  # entry. `lib.nameValuePair` builds one such entry, and `source` is what the
  # link points to.
  home.file = lib.mapAttrs' (_agent: path: lib.nameValuePair path { source = rules; }) ruleFiles;
}
