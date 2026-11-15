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

You can type `/tuih help` to get a tooltip for all available commands, by simply hovering over the printed chat message. 'TUIH  -  hover here for help'.

---

You can setup a lot of keybindings in options -> keybindings -> True UI Hide.

---

You can find some settings for True UI Hide in options, at the 'AddOns' tab at 'True UI Hide'.

Configure which UI elements should stay visible when toggling off the UI.

Configure whether the UI should be re-enabled when entering combat. This is advised to be kept on, since the UI cannot be easily toggled during combat. Blizzard locks certain changes during combat.

Presets: Not yet final, but change between some presets to leave things like the minimap during UI hide.

## Presets

True UI Hide supports built in and custom presets.

See preset commands to use.

Feature not yet fully tested and may change in the future.

## Available commands

Commands may change soon, since this addon is in early development.

| Command | Aliases | Description |
|---|---|---|
| `/tuih` | | Toggle all UI, names and nameplates |
| `/tuih on` | | Show everything and restore your saved settings |
| `/tuih off` | | Hide everything |
| `/tuih p` | `players`, `/tuihp` | Cycle player names: none, own only, others only, own and others (also hides player nameplates) |
| `/tuih minimap` | `map`, `m` | Keep the minimap while the UI is hidden |
| `/tuih player` | `pf` | Keep the player frame |
| `/tuih target` | `tf`, `t` | Keep the target frame |
| `/tuih plates` | `nameplates`, `np`, `ep` | Keep enemy nameplates |
| `/tuih chat` | `c` | Keep the chat |
| `/tuih bars` | `actionbar`, `ab` | Keep the action bars |
| `/tuih buffs` | `auras`, `b` | Keep buffs and debuffs |
| `/tuih quest` | `tracker`, `q` | Keep the quest tracker |
| `/tuih questie` | `qt` | Keep the Questie tracker (only if Questie is installed) |
| `/tuih cast` | `cb` | Keep the cast bar |
| `/tuih combat` | | Show the UI automatically during combat |
| `/tuih normal` | | Preset: reset everything |
| `/tuih explore` | | Preset: keep minimap and chat |
| `/tuih social` | | Preset: keep chat and player frame, show all player names |
| `/tuih immersive` | | Preset: hide everything, UI returns in combat |
| `/tuih screenshot` | | Preset: hide everything, also in combat |
| `/tuih preset save <name>` | | Save the current state as your own preset |
| `/tuih preset delete <name>` | | Delete one of your presets |
| `/tuih preset list` | | List all presets |
| `/tuih <preset>` | | Apply a built-in or custom preset |
| `/tuih shot` | `ss` | Take a screenshot without UI |
| `/tuih config` | `cfg`, `options`, `o` | Open the options panel |
| `/tuih status` | `s` | Show the current settings |
| `/tuih reset` | | Reset everything and clear the saved state |
| `/tuih diff` | `d` | Find the CVar behind a menu option (run once, change the option, run again) |
| `/tuih help` | `h`, `?` | Print a hoverable help link |

### Keybindings

Options > Keybindings > True UI Hide

| Action | Description |
|---|---|
| Toggle UI and names | Same as `/tuih` |
| Cycle player names | Same as `/tuih p` |
| Peek: show UI while held | UI is visible only while the key is held |
| Peek: hide UI while held | UI is hidden only while the key is held |
| Screenshot without UI | Same as `/tuih shot` |
| Open options | Same as `/tuih config` |
| Show help link | Same as `/tuih help` |
| Preset: normal | Same as `/tuih normal` |
| Preset: explore | Same as `/tuih explore` |
| Preset: social | Same as `/tuih social` |
| Preset: immersive | Same as `/tuih immersive` |
| Preset: screenshot | Same as `/tuih screenshot` |
| Keep: Minimap | Same as `/tuih minimap` |
| Keep: Player frame | Same as `/tuih player` |
| Keep: Target frame | Same as `/tuih target` |
| Keep: Enemy nameplates | Same as `/tuih plates` |
| Keep: Chat | Same as `/tuih chat` |
| Keep: Action bars | Same as `/tuih bars` |
| Keep: Buffs and debuffs | Same as `/tuih buffs` |
| Keep: Quest tracker | Same as `/tuih quest` |
| Keep: Questie tracker | Same as `/tuih questie` (does nothing without Questie) |
| Keep: Cast bar | Same as `/tuih cast` |

These commands have no keybinding and are chat-only: `/tuih on`, `/tuih off`, `/tuih combat`, `/tuih status`, `/tuih reset`, `/tuih diff`, `/tuih preset ...`.

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
