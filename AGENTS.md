# Agent instructions

This repository is a Nix flake. It builds the operating system settings for the machines it manages.

Read this file first. Then read the `AGENTS.md` in each folder you change. Each one lists the folder's files and the rules that apply there. For the human overview and glossary, read [README.md](README.md).

## Subdirectories

- [modules/](modules/AGENTS.md): the loader and every setting it loads.

## Keeping these files current

Keep the `AGENTS.md` files and the README accurate as part of every change.

1. When you add, remove, rename, or change the purpose of a file, update the `AGENTS.md` in the same folder.
2. When you create a folder that holds files, add an `AGENTS.md` to it, and link it from the parent's Subdirectories section.
3. When you remove a folder, delete its `AGENTS.md` and remove its link from the parent.
4. When a change affects the layout, the commands, the loading order, or a glossary term, update `README.md` too.
5. When a rule appears in more than one `AGENTS.md`, update every copy.
6. Before you finish, check that each `AGENTS.md` in the folders you touched matches the files there. Fix any mismatch you find.

Every child `AGENTS.md` ends with a short version of rule 1 to 3, so the rule still applies when an agent reads that file alone.

## Writing style for comments and docs

Write for a reader who knows some programming but has never used Nix.

- Start every `.nix` file with a comment that says what it configures and where it loads from.
- Comment every setting. Say what it does and why it is set that way.
- Explain a Nix idiom the first time a file uses it. Idioms include `let ... in`, `inherit`, `with`, `${...}`, `lib.mkDefault`, and `optionalAttrs`.
- Use plain words. Name the concrete thing, not an abstract one.
- Use sentence case for headings and straight quotes.
- Do not use em dashes or en dashes. Use a period or a comma instead.
- Use a colon only before a list or an example.
- Do not start a line with a bold label that repeats the line. Do not bold proper nouns or acronyms.
- Do not add decorative emoji.

## Boundaries

- Do not edit `flake.lock` by hand. Use `nix flake update`.
- Do not edit `modules/machines/reatan-x7-00/nixos/hosts/nixos/hardware-configuration.nix`. It is generated, and its header forbids edits. Regenerate it when the hardware changes.
- Do not change a `stateVersion` value. Changing it can change defaults and break existing data.

## Verify your change

Run these from the repository root. The first run downloads the inputs, so it can be slow.

- `nix-instantiate --parse <file>.nix` checks the syntax of one file. It does not check that a setting is valid.
- `nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath` prints the path of the whole system's build plan. Run it before and after your change. A documentation-only change must leave the value the same.
- Run `git add` on new files first. Nix ignores files that git does not track.
