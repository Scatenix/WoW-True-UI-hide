# True UI Hide

True UI Hide is a World of Warcraft Forever addon to expand on the already existing UI hide (Alt+Z).

Alt+Z only hides the top level UI but not things in the 3D world, like player names.
This can be achieved through some settings, but is tedious to do.

True UI Hide solves this, by letting you assign hotkeys to achieve this (or chat commands).

Disclaimer: Addon is mainly written by AI but the I checked the generated code and made small adjustments.

Second Disclaimer: This addon might permanently overwrite some of your settings, like which names to show on players and NPCs. It should not do that, but there might be bugs. Before toggling the UI off, your settings are written into a DB that hopefully survives even a crash and is reset when toggling the UI on again. (DB stored `<YOUR-WOW-INSTALL-DIR>/_forever_/WTF/Account/<ACCOUNT_ID>/SavedVariables/TrueUIhide.lua`)

## Getting started

Todo: Add automatic release pipeline to bundle addon into a zip.
Todo: think about publishing on some mod website

Simply copy paste the `TrueUIhide` folder to your addons folder.
into: `<YOUR-WOW-INSTALL-DIR>/_forever_/Interface/AddOns/`

If your game is running, make sure to run `/reload` in the in-game chat.

## Using

Disclaimer for a Small quirk: If you toggle the UI off and hit escape, press Alt+Z or change some appearance settings (or similar), this UI is in a somewhat unstable state. Toggle tuih again to be in a stable "normal" state again.

If you have Questie installed, this addon automatically detects it and gives you the option to show it during the UI hide mode.

---

Every addon message starts with a `[TUIH]` tag: hover it for a short overview. Type `/tuih help` to get one hoverable link per topic (Main, Elements, Presets, Settings), each showing the commands for that topic in its own tooltip.

---

You can setup a lot of keybindings in options -> keybindings -> True UI Hide.

---

A small icon on the minimap border opens the settings with a click. Drag it to move it around the minimap. It can be hidden in the settings (or with `/tuih set icon`).

A small red dot appears slightly up and left of the screen center when the UI is visible but hide settings are still applied, meaning we are in an unstable state (for example after the game showed the UI on Escape, or a restore was blocked by combat). Left-click restores everything, right-click hides the UI again. It disappears on its own once the state is clean. It can be turned off in the settings (or with `/tuih set dot`).

You can find some settings for True UI Hide in options, at the 'AddOns' tab at 'True UI Hide'.

Configure which UI elements should stay visible when toggling off the UI.

Configure whether the UI should be re-enabled when entering combat. This is advised to be kept on, since the UI cannot be easily toggled during combat. Blizzard locks certain changes during combat.

Presets: Not yet final, but change between some presets to leave things like the minimap during UI hide.

## Presets

True UI Hide supports built in and custom presets.

See the preset commands below (`/tuih preset ...`). The settings panel has one section for the built-in presets and one for your custom presets.

Feature not yet fully tested and may change in the future.

## Reset vs. delete all data

- **Reset** (`/tuih reset`, or the Reset button in the settings): back to normal. Shows the UI, restores your game settings and clears the kept elements. Your presets and options stay. Use it when the UI or the names look wrong.
- **Delete all data** (`/tuih wipe`, or the button in the settings): the nuclear option. Restores your game settings first (only if the addon is in hide mode), then deletes everything the addon saved (presets, options, icon position) and starts fresh. Use it when the addon itself misbehaves. Not possible in combat; nothing is deleted if the game settings cannot be restored.

## Available commands

Commands may change soon, since this addon is in early development.

The most used commands sit at the root. Everything else is grouped: `/tuih toggle ...` for UI elements, `/tuih preset ...` for presets and `/tuih set ...` for settings.

### Root

| Command | Aliases | Description |
|---|---|---|
| `/tuih` | | Toggle all UI, names and nameplates |
| `/tuih on` | | Show everything and restore your saved settings |
| `/tuih off` | | Hide everything |
| `/tuih players` | `p` | Cycle player names: none, own only, others only, own and others (also hides player nameplates) |
| `/tuih shot` | `ss` | Take a screenshot without UI |
| `/tuih mouselook` | `look`, `ml` | Enter or leave mouselook, right-click style (right-click ends it) |
| `/tuih status` | `s` | Show the current settings |
| `/tuih config` | `cfg`, `options`, `o` | Open the options panel |
| `/tuih reset` | | Reset everything and clear the saved state |
| `/tuih wipe` | | Nuclear option: restore your game settings, then delete ALL addon data and start fresh. Asks you to run `/tuih wipe confirm` |
| `/tuih help` | `h`, `?` | Print the hoverable help links, one per topic |
| `/tuih diff` | `d` | Find the CVar behind a menu option (run once, change the option, run again) |

### Elements kept visible: `/tuih toggle <element>`

`/tuih toggle` (aliases `keep`, `k`) without an element lists the available elements.

| Element | Aliases | Keeps this visible while the UI is hidden |
|---|---|---|
| `/tuih toggle minimap` | `map`, `m` | Minimap |
| `/tuih toggle player` | `pf` | Player frame |
| `/tuih toggle target` | `tf`, `t` | Target frame |
| `/tuih toggle enemyplates` | `plates`, `nameplates`, `np`, `ep` | Enemy nameplates |
| `/tuih toggle chat` | `c` | Chat |
| `/tuih toggle actionbars` | `bars`, `actionbar`, `ab` | Action bars |
| `/tuih toggle buffs` | `b`, `auras` | Buffs and debuffs |
| `/tuih toggle quest` | `q`, `tracker` | Quest tracker |
| `/tuih toggle questie` | `qt` | Questie tracker (only if Questie is installed) |
| `/tuih toggle castbar` | `cast`, `cb` | Cast bar |

### Presets: `/tuih preset ...`

| Command | Description |
|---|---|
| `/tuih preset <name>` | Apply a built-in or custom preset |
| `/tuih preset list` | List all presets |
| `/tuih preset save <name>` | Save the current state as your own preset |
| `/tuih preset delete <name>` | Delete one of your presets |

Built-in presets: `normal` (reset everything), `explore` (keep minimap and chat), `social` (keep chat and player frame, show all player names), `immersive` (hide everything, UI returns in combat), `screenshot` (hide everything, also in combat).

Custom preset names may use letters, digits, `-` and `_` (up to 24 characters). `save`, `delete`, `list`, `normal` and the built-in names are reserved.

### Settings: `/tuih set ...`

| Command | Description |
|---|---|
| `/tuih set combat` | Show the UI automatically during combat |
| `/tuih set mouselook` | Enter mouselook whenever the UI is hidden |
| `/tuih set icon` | Show or hide the minimap icon |
| `/tuih set shotcombat` | Show the UI if combat starts during a screenshot (on by default) |
| `/tuih set dot` | Show or hide the red warning dot (on by default) |
| `/tuih set verbose` | Show True UI Hide events in chat for debugging ("UI on", "Preset: ...", ...). Off by default |

### Keybindings

Options > Keybindings > True UI Hide. They are grouped into Main, Presets, Toggle elements and Other.

| Action | Description |
|---|---|
| Toggle UI and names | Same as `/tuih` |
| Peek: show UI while held | UI is visible only while the key is held |
| Peek: hide UI while held | UI is hidden only while the key is held |
| Cycle player names | Same as `/tuih players` |
| Screenshot without UI | Same as `/tuih shot` |
| Mouselook (right-click style) | Same as `/tuih mouselook` |
| Preset: normal / explore / social / immersive / screenshot | Same as `/tuih preset <name>` |
| Toggle: Minimap, Player frame, Target frame, Enemy nameplates, Chat, Action bars, Buffs and debuffs, Quest tracker, Questie tracker, Cast bar | Same as `/tuih toggle <element>` (Questie does nothing without Questie) |
| Open options | Same as `/tuih config` |
| Show help links | Same as `/tuih help` |

These commands have no keybinding and are chat-only: `/tuih on`, `/tuih off`, `/tuih status`, `/tuih reset`, `/tuih diff`, `/tuih set ...`, `/tuih preset save|delete|list` and custom presets.

## Todos

Don't mind this. It's for me, the dev :)
And this is also not a promise.

- Better pre-built presets
- Better custom presets support (especially the command to set a custom preset, which easily leads to name collisions)
- change some commands, because its confusing
- Improve readme (descripe commands like diff, add troubleshooting, document quirks, add pictures)
- Add/Change/Remove keybinds
- Release Pipeline
- Maybe publish addon somewhere
- Review the save system with the DB and check what all of the stuff in `<YOUR-WOW-INSTALL-DIR>/_forever_/WTF/Account/<ACCOUNT_ID>/SavedVariables/TrueUIhide.lua` is
- What happens if the game is restarted with UI hidden?

## Legal

MIT License (exists within the Addon directory)

Please give me credit if modifying and or redistributing :)
