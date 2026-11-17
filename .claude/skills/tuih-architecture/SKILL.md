---
name: tuih-architecture
description: How the True UI Hide WoW addon works internally (modules, saved variables, hide/restore flow, frame detaching, CVar handling, combat, peek, screenshot) plus its invariants and known quirks. Load before reading, changing, or debugging any code in TrueUIhide/.
---

# True UI Hide: architecture

Goal of the addon: hide ALL UI (Alt+Z only hides UIParent). It hides `UIParent`, turns name/nameplate/soft-target/combat-text CVars off, and keeps chosen things visible ("keep elements"). Everything is reversible; the original CVar values are saved first.

## Modules (TOC load order, `TrueUIhide/TrueUIhide.toc`)
Every file starts with `local _, ns = ...` (shared namespace). Cross-module calls go through `ns.*`; they are resolved at call time, so file order only matters for code that runs at load.

| File | Role |
|---|---|
| Core.lua | `ns.log` (always) / `ns.info` (only if `TUIHDB.verbose`), `sanitize()` + `ns.initDB()`, `ns.state`, login/logout hooks (auto-restore), welcome message |
| Data.lua | static data: `ns.baseCVars`, `ns.combatTextCVars`, `ns.prefixes`, `ns.keepGroups`, `ns.keepList` (the keep elements), `ns.builtin` + `ns.presetOrder`, `ns.stageNames`, `ns.available` |
| CVars.lua | CVar list, snapshot/hide/restore, ownership (`ns.ownsCVar`, `ns.isKept`), name stages, resets to game defaults |
| Frames.lua | detach/attach of frames, `ns.sync`, `ns.syncKeptCVars`, `ns.syncPlates`, `ns.applyUI`, bag fullscreen hook, own windows (custom frames) and the mouse picker |
| Actions.lua | `ns.setAll(show)`, `ns.userSetAll`, keep toggles, `ns.toggleKeepAll`, player name stage setters, `ns.toggle` |
| Presets.lua | apply/save/delete/cycle presets, `ns.reset`, `ns.wipeAll`, `RESERVED_NAMES` |
| Peek.lua | hold-key peek, screenshot flow (`ns.shot`, `ns.abortShot`) |
| Mouselook.lua | optional cursor hiding via mouselook |
| Combat.lua | show UI in combat (`PLAYER_REGEN_*`), deferred work after combat |
| Indicator.lua | red warning dot for unstable states |
| Diag.lua | `ns.diff` (find the CVar behind a menu option), `ns.status` |
| Options.lua | settings panel (scroll frame, hand-placed Y offsets), popups, registration with the Settings API |
| MinimapButton.lua | draggable minimap icon (no libraries) |
| Help.lua | hoverable `[TUIH]` chat links and tooltips (`ns.helpGroups`) |
| Commands.lua | `/tuih` handler table |
| Binds.lua + Bindings.xml | keybinding labels and the global `TUIH_*` functions called by the XML |

## Saved variables: global `TUIHDB`
`sanitize()` in Core.lua validates every key on load (corrupted/hand-edited files must not break commands). Add new keys there.
- `keep` {key -> true}: kept elements; own windows are stored as `"frame:<FrameName>"`.
- `customFrames` {FrameName -> true}: the list of own windows; `customLimit` (nil = default 100).
- `presets` {name -> {keep, combat, players}}: custom presets.
- `saved` {cvar -> string} or nil: original CVar values while hidden (or leftovers after a failed restore). `nil` means "nothing to restore".
- `playerNames` 0..3, `combatShow`, `mouselookAuto`, `shotCombatShow`, `shotBefore`/`shotAfter` (0.1..3), `cycleMessage`, `indicator`, `minimapIcon`, `minimapAngle`, `verbose`, `welcomed`, `combatNotice` (one-time flag).
- The file is only written on logout or `/reload`.
- Migrations: none exist today (pre-1.0 green field). From `v1.0.0` on, existing users have saved data, so key renames/removals/meaning changes need a deliberate decision (see CLAUDE.md). There is no schema version field; add one only if a migration needs it.

## Hide / show flow
`ns.toggle` -> `ns.userSetAll(show)` (aborts a running screenshot, clears pending/autoShown/peek) -> `ns.setAll(show)`:
- hide: `ns.hideAll()`, then `ns.applyUI(false)` (`UIParent:SetShown`, `ns.sync()`, optional mouselook), then `ns.setStage(TUIHDB.playerNames)`.
- show: `ns.restore(quiet)`, then `ns.applyUI(true)`.

CVars (CVars.lua):
- `ns.cvarList()` = `baseCVars` + every console command whose name starts with one of `ns.prefixes` (`unitname`, `nameplateshow`, `softtarget`); cached; CVars that do not exist in the client are skipped (`GetCVar == nil`).
- `ns.hideAll()`: `ns.snapshot()` (merge-only into `TUIHDB.saved`, so a partial restore never loses originals), then sets every listed CVar to "0" except kept ones (`ns.isKept`), enemy nameplates (special case, `keep.enemyplates`) and plate CVars in combat. Remembers what it set in the runtime table `applied`.
- `ns.setCVar(c, v, isRestore)`: `pcall(SetCVar)` then a read-back with `GetCVar` (blocked actions in combat do not raise errors, so only the read-back proves success). Numeric tolerant compare (`sameValue`).
- `ns.restore()` per CVar: missing -> skip; already equals saved -> nothing; differs from `applied` -> the player changed it while hidden -> keep their value ("Kept your change", once per value, verbose only); plates in combat -> stays in `saved` (pending); else `setCVar(saved)`. `TUIHDB.saved` becomes nil only when nothing is pending.
- Ownership: an element with `cvars = {...}` or `match = function(c)` owns those CVars. Not kept -> forced to "0" while hidden; kept -> original value stays/returns. The three player-name CVars (`unitnameown`, `unitnamefriendlyplayername`, `unitnameenemyplayername`) belong to the name stage instead (`ns.setStage`, `ns.hidePlayerPlates`), not to a keep element.
- Auto-restore: `PLAYER_LOGOUT` (also fires on `/reload`) calls restore quietly; `PLAYER_LOGIN` restores leftovers if `saved` exists and UIParent is shown.

## Frames (Frames.lua)
- Elements with `frames` (names, or a function returning names/frame objects; unknown names are ignored) are "detached": `SetParent(WorldFrame)`, scale multiplied by `UIParent:GetEffectiveScale()/WorldFrame:GetEffectiveScale()`, anchors re-applied (a nil anchor target is pinned to UIParent). Only frames whose parent is `UIParent` are touched. `attach` undoes it from the stored state in `detached`.
- `ns.sync()` is one pass: a frame is wanted if ANY element or own-window entry wants it (the same frame can be in both); frames still in `detached` but no longer in any list are attached again. In combat it only sets `ns.state.needsSync` (Combat.lua syncs after combat). During a screenshot (`shotMode`) nothing is kept.
- Bags: the game refuses to open bags unless its "fullscreen frame" is shown (`ContainerFrame_AllowedToOpenBags`). The element has `fullscreen = true`: while hidden, `ContainerFrame_SetFullScreenFrame(standIn)` is used, where `standIn` is a child of WorldFrame anchored to UIParent with the same effective scale (so size and position stay right). `ContainerFrameContainer` is detached as well, otherwise the game lays bags out wrongly.
- Load-on-demand windows (auction, talents, ...) are picked up by an `ADDON_LOADED` sync while hidden.
- Own windows: `ns.addCustomFrame/removeCustomFrame/setCustomKeep`, `ns.pickFrame` (mouse focus -> walks up to the named child of UIParent; refuses unnamed or already detached frames), limit `ns.customLimit()`.
- `ns.hasDetached()` is true while any frame (or the bag hook) is active; used by the dot, wipe, reset.

## Combat, peek, screenshot
- Combat.lua: on `PLAYER_REGEN_DISABLED` the UI is shown (if `combatShow`) by calling protected show/hide inside the event handler, which the game allows (verified by the maintainer). A running peek is ended first; a running screenshot is aborted when `shotCombatShow`. `ns.state.autoShown/autoStage` remember what to redo on `PLAYER_REGEN_ENABLED`; `ns.state.pending == "show"` is a show that was blocked by combat.
- Peek.lua: `peekShow/peekHide` (key down/up). A lost key-up is handled by `ns.endPeek()` (called on the next key down, on combat, on `PLAYER_ENTERING_WORLD`).
- Screenshot: `ns.shot` sets `shotMode/shotBusy`, hides everything (also kept elements), waits `shotBefore`, `Screenshot()`, waits `shotAfter`, `finishShot`. `ns.state.shotCtx` holds the timers.

## Presets
- `ns.builtin[name] = {keep, players}` (+ optional `combat`), order in `ns.presetOrder`. Custom presets in `TUIHDB.presets`.
- Command/keybind: `ns.applyPreset` sets keep/players/combat, then `ns.userSetAll(false)` + `ns.syncPlates()` (it HIDES the UI). The panel: `ns.applyPresetSettings` changes settings only.
- Cycling uses `ns.state.presetCurrent`; unknown current -> first (forward) or last (backward).
- "Back to normal" is `ns.reset` (keep cleared, combat default, UI shown, `saved = nil`) and is not a preset. `ns.wipeAll` restores first (only if hide mode is active), then wipes `TUIHDB` and calls `ns.initDB()`.

## Indicator, logging, help
- Indicator.lua: red dot (20 px, WorldFrame CENTER offset -160/120) shown when UIParent is shown AND (`TUIHDB.saved ~= nil` or `ns.hasDetached()`) AND the setting is on AND no screenshot. Hooks `ns.setAll`. Left click `userSetAll(true)`, right click `userSetAll(false)`.
- Every chat message goes through `ns.log(msg, key)` which prefixes a hoverable `[TUIH]` link (`|Haddon:TUIH:<key>|h`). Help.lua hooks `OnHyperlinkEnter` on all chat frames (also temporary windows via `FCF_OpenTemporaryWindow`). Help tooltips are per topic so none grows taller than the screen.
- Commands: handler table `add(fn, "name", "alias", ...)`; handlers receive `(lowercased arg, raw arg)`. Frame names are case-sensitive, so use the raw arg for them.

## Settings panel (Options.lua)
- `ScrollFrame` -> `content`. Layout is hand-placed with negative Y offsets: title, note (-70), keep groups from y=-112 (`groupHeader`, two columns at x=16 and 286), own windows block (rows are created on `content`, NOT on `host`, because `host` changes later), then `mid` (player names dropdown + presets, moved by `ns.moveMid` when the own-windows list grows), then `tail` (options, screenshot, limits, maintenance at `TAIL_MAINT`, soft-target section). `setHeight()` computes the scroll height from `baseTy` and `TAIL_MAINT`. When inserting a section, shift the later constants and check `setHeight`.
- `refreshers` run on every panel show and via `ns.refreshOptions()`; any command that changes settings should call it so an open panel updates.
- Registration: `Settings.RegisterCanvasLayoutCategory` with fallback to `InterfaceOptions_AddCategory`.

## Quirks and traps
- `UIParent` hidden means anything parented to it is hidden, and the game blocks opening some windows (bags). Windows reparented to WorldFrame can drift slightly in position/scale because the game re-anchors them with offsets in their own scale units (popups are the likeliest).
- Escape and some menus show `UIParent` again: this leaves hide settings active ("unstable state"); that is what the red dot is for.
- Name CVar `UnitNameHostleNPC` is spelled that way by Blizzard (do not "fix" it).
- Popups (`StaticPopup1-4`) are used by secure code: reparenting them is a taint risk. If "action blocked" errors ever appear, suspect the `popups` element first, then other window elements.
- Nameplate CVars cannot be changed in combat (read-back check catches it).
- With chat hidden you cannot type commands: keep chat if you need `/tuih` while hidden (or use keybinds).
- Floating combat text and quest circles are now hidden by default while the UI is hidden unless kept (they used to stay visible).
- Presets store `keep` including `frame:<name>` keys; built-in presets keep no own windows.
- The game client is Classic-based but uses Mainline-style code in places (bag code lives under `Blizzard_UIPanels_Game/Mainline/`). Retail API names usually apply; verify with a runtime check before relying on them.
