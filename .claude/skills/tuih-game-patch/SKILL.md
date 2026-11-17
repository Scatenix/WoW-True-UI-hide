---
name: tuih-game-patch
description: What to do when a World of Warcraft patch or client update may affect True UI Hide - bump the Interface number, find renamed or removed APIs, frame names and CVars, add guards, and what to test. Load when the maintainer mentions a game patch, "addon out of date", Lua errors after an update, or a new client version.
---

# Maintaining True UI Hide across game patches

## 1. Interface number
- `TrueUIhide/TrueUIhide.toc` has `## Interface: 16001`. The game marks the addon "out of date" when it differs from the client's number. The release pipeline does NOT touch this line (it only rewrites `## Version:`).
- Ask the maintainer to run in game: `/dump (select(4, GetBuildInfo()))` and use that number. A comma-separated list (`## Interface: 16001, 50503`) works if several clients must be supported; do not add numbers you have not confirmed.
- Changing only this number (plus a release) is the normal "patch day" fix. Release via `tuih-release`.

## 2. The addon's API surface = `.luacheckrc` `read_globals`
That list is every game global the addon reads. After a patch, review it for renamed/removed functions, and when you add code that uses a new game API add the name there (CI lint fails on unknown globals).

Known fragile points and their guards:
| Area | What the code does | If it breaks |
|---|---|---|
| Mouse focus | `GetMouseFoci` (new) with fallback `GetMouseFocus` (old) in `Frames.lua` `frameUnderMouse` | one of them may vanish; keep both branches |
| Settings panel | `Settings.RegisterCanvasLayoutCategory` with fallback `InterfaceOptions_AddCategory`; `Settings.OpenToCategory`/`InterfaceOptionsFrame_OpenToCategory` in `ns.openConfig` | keep both paths; a client may remove the old one |
| Dropdown | `UIDropDownMenuTemplate` + `UIDropDownMenu_*` (player names in Options.lua) | newer clients replace it with the Menu API; if the old API disappears, rebuild this dropdown (or use a cycling button as a fallback) |
| Console commands | `C_Console.GetAllCommands` or `ConsoleGetAllCommands` (CVars.lua `ns.getAllCommands`) | CVar discovery by prefix depends on it; if both vanish only `ns.baseCVars` remains |
| Timers | `C_Timer.After/NewTimer` | stable |
| Bags | `ContainerFrame_SetFullScreenFrame/ClearFullScreenFrame` (guarded by `if ContainerFrame_SetFullScreenFrame`) | if renamed, the bags element silently stops working while hidden |
| Taint-prone | `SetParent/SetScale/SetPoint` on Blizzard frames | see taint notes in `tuih-architecture` |
| Combat | protected show/hide in `PLAYER_REGEN_DISABLED` handler | if a patch changes lockdown timing, the combat auto-show breaks: test it |

Always prefer `if fn then` guards or `pcall` over assuming an API exists; a Lua error at load disables the whole addon.

## 3. Frame names and CVars
- Keep elements list frame names for several client versions; unknown names are skipped silently, so a patch that renames a frame makes that element do nothing without any error. To check names in game the maintainer uses `/fstack` (hover) or the addon's own `/tuih keepframe pick` (adds the window under the mouse; its output includes the real name).
- CVars: discovery is automatic for the prefixes `unitname`, `nameplateshow`, `softtarget`. Explicit lists: `ns.baseCVars`, `ns.combatTextCVars`, element `cvars`. A removed CVar is skipped (`GetCVar == nil`); a new related CVar family needs a prefix or an explicit entry. Use `/tuih diff` (baseline, change a menu option, diff) to find which CVar a menu option controls.
- Look at the Blizzard source for the new version before guessing: `https://raw.githubusercontent.com/Gethe/wow-ui-source/<branch or tag>/Interface/AddOns/...` (branch `live` worked; other branches/tags exist per client flavor). Compare the files the addon depends on (bags: `Blizzard_UIPanels_Game/*/ContainerFrame.lua`).
- API change lists: warcraft.wiki.gg "Patch X.Y.Z/API changes".

## 4. Test list after a patch (ask the maintainer to run, report what fails)
1. Login without Lua errors; the panel opens (Esc > Options > AddOns > True UI Hide); minimap icon visible.
2. `/tuih` hides everything, `/tuih` restores names and nameplates (compare before/after).
3. A kept window opens while hidden: bags, a vendor, loot.
4. Combat starts while hidden: UI comes back, and goes away again after combat.
5. `/tuih keepframe pick` on any window.
6. Keybinds are listed under Options > Keybindings > True UI Hide.

## 5. If the addon fails to load
Lua error text is in the game's error popup or `Logs/`/BugSack. A syntax or missing-global error at load disables everything. Fix with guards, `luac -p`, then a release. Never ship a speculative fix as a release without telling the maintainer it is untested.
