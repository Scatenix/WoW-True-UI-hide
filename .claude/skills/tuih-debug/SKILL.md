---
name: tuih-debug
description: How to investigate True UI Hide bug reports without a game running on your side - reading the SavedVariables file, temporary in-game debug dumps, reading Blizzard source, mock-testing Lua logic, and a symptom-to-cause table. Load when the maintainer reports misbehavior in the game (names showing, UI stuck, windows missing or misplaced, settings changed, errors).
---

# Debugging True UI Hide

> Hard rule (see CLAUDE.md): never implement anything without an explicit go from the maintainer. A question like "what is next?" is a question, not a go.

You cannot run WoW. The maintainer can, but cannot copy text out of the chat and dislikes long manual procedures. So: collect evidence from files, keep requests to the maintainer to 3-4 simple steps, and say exactly when to `/reload`.

## Evidence channel 1: the SavedVariables file
- Path (this maintainer): `/Applications/World of Warcraft/_forever_/WTF/Account/<ACCOUNT>/SavedVariables/TrueUIhide.lua` (find it with `ls "/Applications/World of Warcraft/_forever_/WTF/Account/"*/SavedVariables/TrueUIhide.lua`). Written only on logout or `/reload`.
- Read it with real Lua (do not eyeball it):
```bash
lua -e 'dofile("<path>"); for k,v in pairs(TUIHDB) do print(k, type(v)=="table" and "table" or tostring(v)) end'
```
  Useful keys: `saved` (non-nil while hidden or after a failed restore: shows which CVars were zeroed and their originals), `keep`, `customFrames`, `presets`, `verbose`.
- A stale `TUIHDB.dbg` may exist from earlier debugging; clear with `/run TUIHDB.dbg=nil` or ignore it.

## Evidence channel 2: a temporary debug dump (the technique that solved the bags and soft-target issues)
1. Add a small temporary function (e.g. in Diag.lua) and a temporary slash command that write facts into `TUIHDB.dbg = { ... }` (strings/numbers only): frame parent chains with `IsShown/IsVisible`, scales and effective scales, strata, first anchor, CVar values, `UIParent:IsShown()`, `ns.hasDetached()`.
2. For "who closes/opens this": `hooksecurefunc(frame, "Show"/"Hide", function() ... debugstack(3, 4, 0) ... end)` appending to a capped list (`#t < 40`) in `TUIHDB`. Stack text shows the Blizzard file and line that triggered it.
3. Ask the maintainer: reproduce the problem, run the temporary command, `/reload`, say "done". Read the file yourself.
4. Remove ALL temporary code afterwards (command, function, hook block, notes) and tell the maintainer. Verify with grep for `dbg`.

## Reading Blizzard code
- The retail source is browsable: `https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/<Addon>/Mainline/<File>.lua` (fetch with curl into the scratchpad, then grep). The client here is Classic-based but runs Mainline-style code for bags and some panels (stack traces from the game show `Blizzard_UIPanels_Game/Mainline/...`), so this is usually right; confirm with a runtime probe (`pcall` each assumption and dump the results).
- Example of the payoff: bags did not open while hidden because `ContainerFrame_AllowedToOpenBags` requires `FullscreenFrame:IsShown()`, and the game offers `ContainerFrame_SetFullScreenFrame(frame)` for exactly this case.

## Mock testing (pure Lua logic outside the game)
- `luac -p file.lua` for syntax (then `rm -f TrueUIhide/luac.out` if one appears; `luac -l` also writes it).
- Load a module with stubs and call it: `assert(loadfile("TrueUIhide/CVars.lua"))("T", ns)` with `ns` pre-filled (`keepList`, `baseCVars`, `prefixes`, `available`, `log`, `info`) and globals stubbed (`GetCVar`, `SetCVar`, `InCombatLockdown`, `UIParent`, `TUIHDB`). A stub table with a `__index` fallback that returns no-op functions is enough to build the whole settings panel (`Options.lua`) and click every button; errors that name stubbed `ns.*` functions are mock gaps, not bugs.
- Put scratch scripts in the session scratchpad, not in the repo. Mocks cannot prove game behavior (taint, protected functions, layout): say so when reporting.

## Symptom -> likely cause
| Symptom | Look at |
|---|---|
| Names/nameplates still show while hidden | a CVar missing from the list (use `/tuih diff` flow: baseline, change option in the menu, diff), an element kept, soft-target or NPC name setting (`UnitNameInteractiveNPC` shows most friendly NPC names), the player-name stage |
| Names stay off after showing | `TUIHDB.saved` leftover (restore pending: combat or read-back failure), `ns.restore` skipped a CVar as "player changed it" |
| UI stuck hidden after combat | `ns.state.pending`/`autoShown` paths in Combat.lua, protected-call restrictions, `ns.state.needsSync` |
| Red dot visible | UIParent shown while `saved ~= nil` or frames detached: something showed the UI (Escape, other addon, Alt+Z); left click fixes |
| A kept window is invisible or off-position | frame name wrong for this client (names are skipped silently), parent is not `UIParent` (not detached), game re-anchors it on show (compare scale/anchors with the dump), load-on-demand frame not yet created |
| A window cannot be opened while hidden | game-side gate like bags (`*_AllowedToOpen*`, `CanOpenPanels`): find it in the Blizzard source and the game's own hook |
| "Action blocked"/taint errors | frames reparented by `Frames.lua`; start with `popups`, then other window elements; reproduce with only that element kept |
| Settings panel misaligned | hand-placed offsets in Options.lua; see `setHeight`/`TAIL_MAINT` in `tuih-architecture` |
| Command does nothing | alias collision in `ns.keepAliases` (the Data.lua sanity check catches it), lowercase vs case-sensitive arg |
| Chat spam | routine messages must use `ns.info`, not `ns.log` |

## Working with the maintainer
- They run the game and commit. Give a short numbered test list (max ~4 steps), say what you changed and what to look for.
- Report honestly what was only mock-tested.
- Keep texts short; no unprompted refactors.
