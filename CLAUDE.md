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
- Keep `README.md` in sync with every change to commands, elements, presets, keybinds, settings. `AUDIT.md` (if present) is a local AI tracking file that the maintainer does not commit (it is not in `.gitignore`, so never `git add` it): update it if it exists.
- No legacy or backward-compatibility code (green field), with the exception of the two leftovers noted in `tuih-architecture`.
- Keep user-facing texts short. Keep chat output quiet: routine confirmations use `ns.info` (verbose only), important messages use `ns.log`.
- Run `luac -p` on every changed Lua file (delete any `luac.out` it leaves). CI runs `luacheck TrueUIhide`; keep it warning-free (config in `.luacheckrc`).
- The maintainer plays the game and reports behavior; they cannot copy text out of the chat. Prefer reading the SavedVariables file over asking for pasted output, and avoid long manual test procedures.
