# Agent skills for the user `chrismg` on the host `nixos`, from the skill
# repositories listed in `skillSources`, such as tstack
# (github.com/t3dotgg/tstack). Loaded by machines.nix as a Home
# Manager module.
#
# A skill is a folder with a SKILL.md file of instructions that a coding agent
# loads when you ask for it by name, such as "council". Each agent reads
# skills from its own folder in the home folder, listed in `skillFolders`
# below. This file links each chosen skill into every one of those folders.
# The links point into the Nix store, so the skills are read-only. Move a
# repository to its newest version with `nix flake update <input>`, such as
# `nix flake update tstack`.
#
# `{ inputs, lib, ... }:` makes this file a function. `inputs` is the flake's
# inputs, and `lib` is the nixpkgs helper library. The `...` ignores the other
# arguments.
{
  inputs,
  lib,
  ...
}:

# `let ... in` defines local names. The names exist only between `let` and `in`.
let
  # The folder, relative to the home folder, where each installed agent reads
  # skills for every project. Add an entry here when you install a new agent.
  skillFolders = {
    # Claude Code reads only its own folder.
    claude-code = ".claude/skills";
    # ~/.agents/skills is the shared folder from the Agent Skills standard.
    # Codex reads it as its user folder.
    codex = ".agents/skills";
    # OpenCode reads ~/.agents/skills too. Sharing the Codex folder, instead
    # of OpenCode's own ~/.config/opencode/skills, gives it one copy fewer,
    # because it also reads ~/.claude/skills. It still finds each skill twice
    # and prints a "duplicate skill name" warning for each one. The warnings
    # are harmless, because OpenCode loads each skill once.
    opencode = ".agents/skills";
    # The Antigravity CLI and app read this folder. They read .agents/skills
    # only inside a project.
    antigravity = ".gemini/config/skills";
  };

  # The skills to install, grouped by the repository they come from. `dir` is
  # the folder in that repository that holds the skill folders, and `names`
  # lists the skill folders to take from it. `${...}` puts a value into a
  # string, here the repository's folder in the Nix store. To add a
  # repository, add it as a flake input with `flake = false` in flake.nix and
  # add an entry here.
  skillSources = [
    {
      dir = "${inputs.tstack}/skills";
      names = [
        # Reviews a change with three models from different providers until they agree.
        "council"
        # Reviews a change with GPT Sol in a loop until both agents agree.
        "sol-loop"
        # Rebases an old pull request and decides if it should still exist.
        "modernize"
        # Formats pull request comments that an agent posts for you. modernize
        # uses it, so it is installed with modernize.
        "leaving-pr-comments"
      ];
    }
  ];

  # Every skill as a pair of its name and its folder in the Nix store.
  # `x: body` is a function that takes `x` and returns `body`. `map` runs a
  # function on each item of a list and returns the list of results.
  # `lib.concatMap` does the same, then joins the lists it gets back into one
  # list. `inherit name;` is short for `name = name;`.
  #
  # Home Manager would still create a link to a skill folder that does not
  # exist, which leaves a broken link. That happens after a typo in `names`, or
  # when a repository renames a skill. So the build stops with an error
  # instead. `builtins.pathExists` checks that the skill has a SKILL.md, and
  # `throw` stops the build with the message after it.
  skills = lib.concatMap (
    source:
    map (
      name:
      let
        path = "${source.dir}/${name}";
      in
      if builtins.pathExists "${path}/SKILL.md" then
        { inherit name path; }
      else
        throw "skills.nix: the skill \"${name}\" has no SKILL.md in ${source.dir}"
    ) source.names
  ) skillSources;

  # Links every skill in `skills` into one skills folder, `dir`.
  # `lib.listToAttrs` turns the list of `{ name; value; }` pairs that `map`
  # returns into a set keyed by `name`, here the link's path in the home
  # folder. `value.source = x;` is short for `value = { source = x; };`, and
  # `source` is what the link points to.
  linkSkills =
    dir:
    lib.listToAttrs (
      map (skill: {
        name = "${dir}/${skill.name}";
        value.source = skill.path;
      }) skills
    );
in
{
  # Files Home Manager creates in the home folder. `lib.attrValues` lists the
  # folders in `skillFolders`, `lib.unique` drops the folder that Codex and
  # OpenCode share, and `lib.mergeAttrsList` joins the links for every folder
  # into one set.
  home.file = lib.mergeAttrsList (map linkSkills (lib.unique (lib.attrValues skillFolders)));
}
