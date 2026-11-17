---
name: tuih-extend
description: Step-by-step recipes for extending the True UI Hide addon - add a keep element (frame or CVar based), built-in preset, setting, slash command, keybinding or settings-panel section - plus the documentation sync checklist and the checks to run. Load when the maintainer asks for a new feature or a change to elements, presets, commands, keybinds or settings.
---

# Extending True UI Hide

Load `tuih-architecture` first if you have not. Never commit. Finish every change with the checklist at the end.

## Add a keep element (Data.lua `ns.keepList`)
One entry; most other places (settings panel, `/tuih toggle`, help tooltip, keybind labels, status, presets) read the list.
```lua
{ key = "loot", group = "windows", label = "Loot windows",
  alias = { "looting" },                 -- optional, must be unique across ALL keys and aliases
  tip = "Shown when hovering the checkbox", -- optional
  frames = lootFrames },                 -- or a table of names, or a function returning names/frames
```
- `group` is one of `ns.keepGroups` keys (`frames`, `names`, `windows`, `bars`). New group: add it to `ns.keepGroups` (the panel draws a header per group, two checkboxes per row).
- Frame based: `frames` (names that do not exist are skipped, so list names for several client versions). Only frames whose parent is `UIParent` can be detached. Frames that load on demand are handled automatically. Use the `numbered("Prefix", n)` helper for `Prefix1..n`.
- CVar based: `cvars = { "ExactCVarName", ... }` or `match = function(c) ... end`. The CVar must also be in `ns.baseCVars` (or match one of `ns.prefixes`) so it is part of the hide/restore list. Not kept = forced to "0" while hidden, so only use CVars where "0" means off.
- Needs another addon: `requires = "GlobalName"`.
- Special cases need code (see `fullscreen` for bags, `enemyplates` for nameplates in `hideAll`/`syncPlates`).
- Then, by hand:
  1. `Bindings.xml`: add `<Binding name="TUIH_KEEP_<KEY>" category="True UI Hide">TUIH_Keep("<key>")</Binding>` at the position matching the list order (the first keep binding carries `header="TUIH_KEEP"`). The label is generated in `Binds.lua`.
  2. README: element table (see below), keybind row is generic ("one per element").
  3. Optionally add the key to built-in presets that should keep it.
- Sanity check (catches typos, duplicate aliases, missing groups):
```bash
cd TrueUIhide && lua -e 'local ns={} UIParent={} WorldFrame={} assert(loadfile("Data.lua"))("T",ns)
local seen={} for _,e in ipairs(ns.keepList) do assert(e.group and e.label,e.key)
 for _,w in ipairs({e.key,table.unpack(e.alias or {})}) do assert(not seen[w] or seen[w]==e.key,"dup "..w) seen[w]=e.key end end
for n,p in pairs(ns.builtin) do for k in pairs(p.keep) do assert(ns.keepByKey[k],n..":"..k) end end print("ok")'; rm -f luac.out
```

## Add or change a built-in preset (Data.lua `ns.builtin`, `ns.presetOrder`)
- `name = { players = 0..3, keep = { key = true, ... }, combat = bool|nil }` (`combat` nil = do not touch the combat option). Add the name to `ns.presetOrder` (display and cycling order).
- Add a binding: `Bindings.xml` `TUIH_PRESET_<NAME>` calling `TUIH_Preset("<name>")` and the label in `Binds.lua` (`BINDING_NAME_TUIH_PRESET_<NAME>`). Custom presets deliberately have no keybinds (the maintainer chose macros: `/tuih preset <name>`).
- Update the README preset table and the keybind row listing preset names. Help.lua lists preset names from the data automatically.
- Reserved custom names live in `RESERVED_NAMES` (Presets.lua); built-in names are reserved automatically.

## Add a setting (saved option)
1. Core.lua `sanitize()`: validate type/range and set the default (a wrong type must never survive a load).
2. Read it where needed via `TUIHDB.<key>`.
3. Panel: Options.lua. Checkbox with `addCheck(y, text, get, set)` in the right section (all `y` values are relative to the section's host; later sections use their own base, see `tuih-architecture`). If you add rows, shift the later fixed offsets (`TAIL_MAINT`, the `y - N` values) and re-check `setHeight()`. A setting that is changed from commands must call `ns.refreshOptions()`.
4. Command: Commands.lua `setCommand` (word -> `ns.toggleXxx`), the usage string, a toggle function that logs with `ns.log` (it is a deliberate user action, not routine info).
5. Help.lua `ns.helpGroups` "settings" row, README `/tuih set` table, `ns.status` line in Diag.lua.
6. If the setting should be reset by "Delete all data": it is automatic (the whole `TUIHDB` is wiped and `ns.initDB()` runs). If "Reset" should touch it, edit `ns.resetState`.

## Add a slash command
- Commands.lua: `add(function(arg, raw) ... end, "name", "alias")`. `arg` is lowercased, `raw` keeps case (needed for frame names). Grouped commands (`toggle`, `preset`, `set`, `keepframe`) have their own sub-dispatch.
- Add it to the right Help.lua group row, the README command table, and the usage text.
- Chat output: `ns.log` for results the user asked for, `ns.info` for routine confirmations (only shown with the verbose setting).

## Add a keybinding
- `Bindings.xml`: `<Binding name="TUIH_X" category="True UI Hide">TUIH_X()</Binding>`; first binding of a section carries `header="TUIH_<SECTION>"` and `BINDING_HEADER_TUIH_<SECTION>` must exist in Binds.lua. Key-up bindings need `runOnUp="true"` and use `keystate`.
- `Binds.lua`: `BINDING_NAME_TUIH_X = "Label"` and the global function `function TUIH_X() ns.something() end`.
- README keybind table.

## Add a settings-panel section
Follow the existing pattern: a `groupHeader`/`heading`, widgets created with the right parent (`content` for the static top, `mid` after the own-windows block, `tail` at the end), a refresher in `refreshers`, and re-check scroll height. Reuse widgets instead of creating new ones on every refresh (pool by index, as the preset buttons and own-window rows do).

## README sync (the maintainer relies on it)
- Element table: generate it from the data so it cannot drift:
```bash
lua -e 'local ns={} UIParent={} WorldFrame={} assert(loadfile("TrueUIhide/Data.lua"))("T",ns)
local gl={} for _,g in ipairs(ns.keepGroups) do gl[g.key]=g.label end local cur
for _,e in ipairs(ns.keepList) do if e.group~=cur then cur=e.group print("GROUP|"..gl[cur]) end
 print(e.key.."|"..table.concat(e.alias or {},", ").."|"..e.label.."|"..(e.tip or "").."|"..(e.requires or "")) end'
```
  (run from the repo root; copy into the table in README "Elements kept visible").
- Also keep in sync: command tables, preset table, keybinding table, settings table, `/tuih set` options, troubleshooting text if behavior changed.

## Checklist before reporting done
1. `luac -p TrueUIhide/*.lua` and `rm -f TrueUIhide/luac.out`.
2. luacheck is run by CI (`luacheck TrueUIhide`, config `.luacheckrc`): no unused variables, no empty branches, new globals declared in `.luacheckrc`. If `luacheck` is installed locally run it.
3. Mock-test logic outside the game when it is pure Lua (see `tuih-debug`).
4. Docs: README, Help.lua, Bindings.xml/Binds.lua, `ns.status`, `AUDIT.md` if present.
5. Tell the maintainer what must be verified in the game (you cannot run WoW) and leave everything uncommitted.
