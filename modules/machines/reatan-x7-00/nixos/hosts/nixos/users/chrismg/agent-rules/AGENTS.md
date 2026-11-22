# chrismg/agent-rules

The global rules for the coding agents of the user `chrismg`. These files are not Nix modules, so the loader does not read them. `../agent-rules.nix` links `global.md` into the global rules file of every installed agent.

## Files

| File | What it does |
| --- | --- |
| `global.md` | The rules every agent reads in every project. Today it names the council members for the council skill: Claude Opus 5.5, GPT Sol 6.1, and Gemini 4 Neon, each at high reasoning effort. |

## Rules

- `global.md` is written for the agents, not for a human reader of this repository. Keep it short, because every agent reads all of it at the start of every session.
- Use the model ids that the agents list, such as `agy models` for Antigravity and the model list in Codex.
- The agents cannot change the linked files, because they point into the Nix store. Change `global.md` here and rebuild.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
