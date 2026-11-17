# True UI Hide: instructions for AI maintainers

World of Warcraft addon (folder `TrueUIhide/`, Lua 5.1). The project is in maintenance mode. These notes and the skills in `.claude/skills/` are written by AI for AI: load the matching skill before working.

Skills (load with the Skill tool when the task matches):
- `tuih-architecture`: how the addon works, saved data, invariants, quirks. Load before changing or debugging any code.
- `tuih-extend`: recipes for adding keep elements, presets, settings, commands, keybinds; documentation sync checklist.
- `tuih-debug`: how to investigate bug reports without the user copy/pasting, mock testing, typical symptoms and causes.
- `tuih-game-patch`: what to do when a WoW patch changes the client (Interface number, API renames, frame names).
- `tuih-release`: how releases work (tag push, pipeline) and what can go wrong.

Rules that always apply:
- NEVER commit or push. The maintainer does all git commits. Leave changes uncommitted and say what changed.
- Keep `README.md` in sync with every change to commands, elements, presets, keybinds, settings.
- Migrations and backward compatibility: while the version is below `v1.0.0` the project is green field, so no legacy handling: when a saved key or feature is removed, delete its handling too and add no migrations. From `v1.0.0` on (check the latest release tag or `## Version:` in `TrueUIhide/TrueUIhide.toc`), saved data of real users exists: whenever you rename, remove or change the meaning of a `TUIHDB` key, a preset field, a keep element key or a CVar, think about whether existing saved data needs a migration (usually in `ns.initDB()`/`sanitize()` in Core.lua). It might, but does not have to: decide per change, explain the reasoning to the maintainer, and remove a migration again once it is no longer needed.
- Keep user-facing texts short. Keep chat output quiet: routine confirmations use `ns.info` (verbose only), important messages use `ns.log`.
- Run `luac -p` on every changed Lua file (delete any `luac.out` it leaves). CI runs `luacheck TrueUIhide`; keep it warning-free (config in `.luacheckrc`).
- The maintainer plays the game and reports behavior; they cannot copy text out of the chat. Prefer reading the SavedVariables file over asking for pasted output, and avoid long manual test procedures.

## `AUDIT.md`: local scratchpad (git-ignored)
`AUDIT.md` in the repo root is your own persistent notebook for this project. It is in `.gitignore`: the maintainer never commits it, and it may not exist yet (create it when you first need it). Use it for anything that must survive between sessions:
- open bugs and their evidence (what was observed, what was ruled out), with a short ID and a status (OPEN / IN PROGRESS / DONE / DROPPED);
- feature requests and ideas the maintainer mentioned but did not ask to build now;
- decisions and their reasons (so you do not re-ask or re-litigate), and things that are verified in the game vs. only mock-tested;
- follow-ups after a release or a game patch.
Rules: read it at the start of a maintenance session; keep it short and current (delete finished items instead of piling up history, git history and the README already record what shipped); one item per heading; never put secrets or account IDs in it. Do not treat it as documentation for humans.
