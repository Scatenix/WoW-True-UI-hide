# True UI Hide

True UI Hide is a World of Warcraft Forever addon to expand on the already existing UI hide (Alt+Z).

Alt+Z only hides the top level UI but not things in the 3D world, like player names.
This can be achieved through some settings, but is tedious to do.

True UI Hide solves this, by letting you assign hotkeys to achieve this (or chat commands).

Disclaimer: Addon is mainly written by AI but the I checked the generated code and made small adjustments.

Second Disclaimer: This addon might permanently overwrite some of your settings, like which names to show on players and NPCs. It should not do that, but there might be bugs. Before toggling the UI off, your settings are written into a DB that hopefully survives even a crash and is reset when toggling the UI on again. (DB stored `<YOUR-WOW-INSTALL-DIR>/_forever_/WTF/Account/<ACCOUNT_ID>/SavedVariables/TrueUIhide.lua`)

## Getting started

Todo: think about publishing on some mod website

Download the latest zip from the GitHub releases page and extract it, or copy the `TrueUIhide` folder from this repository,
into: `<YOUR-WOW-INSTALL-DIR>/_forever_/Interface/AddOns/`

If your game is running, make sure to run `/reload` in the in-game chat.

## Using

Disclaimer for a Small quirk: If you toggle the UI off and hit escape, press Alt+Z or change some appearance settings (or similar), this UI is in a somewhat unstable state. Toggle tuih again to be in a stable "normal" state again. If you change a name or nameplate option while the UI is hidden, your new value is kept when the UI comes back. Options you did not touch go back to what they were before.

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

See the preset commands below (`/tuih preset ...`). The settings panel has one section for the built-in presets and one for your custom presets. Clicking a preset there only changes the settings (kept elements and the combat option) and does not hide the UI. The commands and keybinds apply the preset and hide the UI. In the custom section, the small x next to a preset deletes it (after a confirmation), and the name field with "Save current as preset" saves the current state under a new name. If the name already exists, the panel asks before overwriting it (the command does not).

Feature not yet fully tested and may change in the future.

## Soft-target settings (advanced)

At the bottom of the settings panel, "Show soft-target settings (advanced)" lists the game's own on/off soft-target settings as plain checkboxes. The game has no menu for them. They are game settings, not addon settings: a change applies immediately and is saved by the game. While the UI is hidden the addon turns all of them off unless "Soft-target highlight" is kept.

## Reset vs. delete all data

- **Reset** (`/tuih reset`, or the Reset button in the settings): back to normal. Shows the UI, restores your game settings and clears the kept elements. Your presets and options stay. Use it when the UI or the names look wrong.
- **Delete all data** (`/tuih wipe`, or the button in the settings): the nuclear option. Restores your game settings first (only if the addon is in hide mode), then deletes everything the addon saved (presets, options, icon position) and starts fresh. Use it when the addon itself misbehaves. Not possible in combat. Nothing is deleted if the game settings cannot be restored.

## Restart, crash and the red dot

- **Restart or `/reload` while the UI is hidden:** your original game settings are put back when you log out or reload. If the game crashes, the addon restores them automatically at the next login (it tells you in chat).
- **Red dot:** if you see a red dot slightly up and left of the screen center while the UI is visible, hide settings are still applied (for example after Escape showed the UI). Left-click restores everything, right-click hides the UI again.

## Troubleshooting

- **The UI or the names look wrong:** run `/tuih reset` (or the Reset button in the settings). It shows the UI, restores your game settings and clears the kept elements.
- **Names or nameplates still look wrong afterwards:** use "Reset name settings" in the settings. It puts all name tag and nameplate settings back to the game's defaults.
- **The addon itself misbehaves:** `/tuih wipe confirm` (or "Delete all data") restores your game settings and deletes everything the addon saved.
- **After a crash:** just log in again. If the addon could not restore everything (for example in combat), it says so: run `/tuih on` after combat.
- **A kept window does not show or looks off:** not every window of the game was tested. Turn the element off and report which one as an issue on GitHub. For your own windows, `/fstack` shows frame names.
- **Soft-target highlight:** hidden together with the UI by default. Keep "Soft-target highlight" to leave it as it is. The game's soft-target settings can also be changed in the settings (advanced section).

## Available commands

Commands may change soon, since this addon is in early development.

The most used commands sit at the root. Everything else is grouped: `/tuih toggle ...` for UI elements, `/tuih preset ...` for presets and `/tuih set ...` for settings.

### Root

| Command | Aliases | Description |
|---|---|---|
| `/tuih` | | Toggle all UI, names and nameplates |
| `/tuih on` | | Show everything and restore your saved settings |
| `/tuih off` | | Hide everything |
| `/tuih players` | `p` | Cycle the player names shown while the UI is hidden: none, own only, others only, own and others. The choice is saved (also set in the settings panel dropdown) |
| `/tuih shot` | `ss` | Take a screenshot without UI |
| `/tuih mouselook` | `look`, `ml` | Enter or leave mouselook, right-click style (right-click ends it) |
| `/tuih status` | `s` | Show the current settings |
| `/tuih config` | `cfg`, `options`, `o` | Open the options panel |
| `/tuih reset` | | Reset everything and clear the saved state |
| `/tuih wipe` | | Nuclear option: restore your game settings, then delete ALL addon data and start fresh. Asks you to run `/tuih wipe confirm` |
| `/tuih help` | `h`, `?` | Print the hoverable help links, one per topic |
| `/tuih diff` | `d` | Find the CVar behind a menu option (run once, change the option, run again) |

### Elements kept visible: `/tuih toggle <element>`

`/tuih toggle` (aliases `keep`, `k`) without an element lists the available elements. `/tuih toggle all` keeps every element and every window of your own list at once, or stops keeping all of them when everything is already kept (also the "Toggle all" button in the settings). It does not touch the UI itself. `/tuih reset` is the full way back to normal.

Keeping an element only leaves it as it is. If it is already turned off in the game (for example friendly nameplates), True UI Hide does not turn it on. The exception is the player names choice (dropdown in the settings, `/tuih players`): it is actually set while the UI is hidden, even if those names were off.

| Element | Aliases | Keeps this visible while the UI is hidden |
|---|---|---|
| **Unit frames and minimap** | | |
| `/tuih toggle minimap` | `map`, `m` | Minimap |
| `/tuih toggle player` | `pf` | Player frame |
| `/tuih toggle target` | `tf`, `t` | Target frame |
| `/tuih toggle pet` | `petframe` | Pet frame |
| `/tuih toggle party` | `group`, `raid` | Party and raid frames |
| `/tuih toggle castbar` | `cast`, `cb` | Cast bar |
| **Names and nameplates** | | |
| `/tuih toggle enemyplates` | `plates`, `nameplates`, `np`, `ep` | Enemy nameplates |
| `/tuih toggle friendlyplates` | `fplates`, `fnp` | Friendly nameplates |
| `/tuih toggle friendlynames` | `fnames`, `fn` | Friendly player names |
| `/tuih toggle npcnames` | `npc`, `npcs` | General NPC names (nPC, hostile NPC and non-combat creature names) |
| `/tuih toggle interactivenpcs` | `inpc`, `interactive` | Interactive NPC names (the game's setting for NPCs you can interact with. In practice this shows most friendly NPC names) |
| `/tuih toggle specialnpcs` | `snpc`, `special` | Special NPC names (the game's setting for special friendly NPCs) |
| `/tuih toggle friendlypets` | `fpets`, `pets` | Friendly pet names (friendly pet, guardian, minion and totem names) |
| `/tuih toggle enemypets` | `epets` | Enemy pet names (enemy pet, guardian, minion and totem names) |
| `/tuih toggle guildtitles` | `guild`, `titles` | Guild names and titles |
| `/tuih toggle softtarget` | `soft`, `st` | Soft-target highlight (the game's soft-target settings (hidden together with the UI by default)) |
| `/tuih toggle questcircles` | `circles`, `qc` | Quest circles (the circles under quest objectives in the world) |
| **Windows** | | |
| `/tuih toggle npcdialogs` | `dialogs`, `gossip` | NPC dialogs (gossip and quest windows, vendors, trainers, flight maps, bank and similar) |
| `/tuih toggle bags` | `bag`, `inventory` | Bags (combined or separate bag windows (needed to sell items to a vendor)) |
| `/tuih toggle loot` | `looting` | Loot windows (the loot window and the group loot roll windows) |
| `/tuih toggle popups` | `popup`, `invites` | Popups and invites (group invites, resurrect and summon requests, duels, ready checks and queue pops) |
| `/tuih toggle trademail` | `trade`, `mail`, `auction` | Trade, mail, auctions (trade, mail, auction house and crafting windows) |
| `/tuih toggle charwindows` | `character`, `spellbook`, `talents`, `worldmap` | Character windows (character, spellbook, talents, friends and the world map) |
| **Bars, chat and text** | | |
| `/tuih toggle chat` | `c` | Chat |
| `/tuih toggle actionbars` | `bars`, `ab`, `actionbar` | Action bars (all action bars, including the stance and pet bars) |
| `/tuih toggle statusbars` | `xp`, `exp`, `rep` | Experience and reputation |
| `/tuih toggle buffs` | `b`, `auras` | Buffs and debuffs |
| `/tuih toggle quest` | `q`, `tracker` | Quest tracker |
| `/tuih toggle questie` | `qt` | Questie tracker (only if Questie is installed) |
| `/tuih toggle messages` | `errors`, `zonetext` | Error and zone text (error messages ("Out of range"), zone names and raid warnings) |
| `/tuih toggle combattext` | `fct`, `damage` | Floating combat text (damage and healing numbers in the world. Hidden by default while the UI is hidden) |

Floating combat text (damage and healing numbers) is hidden together with the UI by default, like the names. Keep it to leave it as it is.

### Your own windows: `/tuih keepframe ...`

Any window that is not in the list above (also windows of other addons) can be kept visible by its frame name.

| Command | Description |
|---|---|
| `/tuih keepframe pick` | Point the mouse at a window within 3 seconds: it is added to your list |
| `/tuih keepframe add <name>` | Add a frame by its name (case-sensitive) |
| `/tuih keepframe toggle <name>` | Turn keeping a listed window on or off (saved per preset) |
| `/tuih keepframe remove <name>` | Remove it from your list |
| `/tuih keepframe` | List your windows |

Aliases: `kf`, `frame`. The same is available in the settings ("Your own windows") and as a keybind (hover a window, press the key). The window has to be open when you pick it. The list of windows is saved with your settings. Whether each one is kept is part of the keep settings, so presets (built-in ones keep none) and "Reset" switch them on or off, while the list itself stays. "Delete all data" removes it. The list holds up to 100 windows. The limit can be raised in the settings ("Limits"). You can also find frame names yourself with the game's `/fstack` command.

### Presets: `/tuih preset ...`

| Command | Description |
|---|---|
| `/tuih preset <name>` | Apply a built-in or custom preset |
| `/tuih preset next` | Apply the next preset, built-in first, then your custom ones (alphabetical), wrapping around |
| `/tuih preset next builtin` | Apply the next built-in preset only |
| `/tuih preset next custom` | Apply the next custom preset only |
| `/tuih preset prev` | Same, backwards. Also `prev builtin` and `prev custom` (alias `previous`) |
| `/tuih preset list` | List all presets |
| `/tuih preset save <name>` | Save the current state as your own preset |
| `/tuih preset delete <name>` | Delete one of your presets |

Built-in presets (each one hides the UI and keeps only what is listed):

| Preset | Keeps | Player names |
|---|---|---|
| `explore` | Minimap, loot windows, popups, NPC dialogs, bags | none |
| `questing` | Minimap, chat, quest tracker, quest circles, interactive NPC names, NPC dialogs, bags, loot windows, popups, cast bar, error text, trade/mail/auctions, character windows | none |
| `social` | Chat, player frame, party and raid frames, friendly player names, guild names and titles, popups, trade/mail/auctions, NPC dialogs | own and others |
| `roleplay` | Chat, friendly player names, guild names and titles, all three NPC name elements, NPC dialogs, popups, loot windows | others only |
| `minimal` | Player and target frame, cast bar, action bars, buffs, party and raid frames, enemy nameplates, error text, popups, loot windows | none |
| `screenshot` | Nothing | none |

Custom preset names may use letters, digits, `-` and `_` (up to 24 characters). `save`, `delete`, `list`, `next`, `prev`, `previous`, `cycle` and the built-in names are reserved.

### Settings: `/tuih set ...`

| Command | Description |
|---|---|
| `/tuih set combat` | Show the UI automatically during combat |
| `/tuih set mouselook` | Enter mouselook whenever the UI is hidden |
| `/tuih set icon` | Show or hide the minimap icon |
| `/tuih set shotcombat` | Show the UI if combat starts during a screenshot (on by default) |
| `/tuih set cyclemessage` | Show a chat message when cycling presets (on by default) |
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
| Reset (back to normal) | Same as `/tuih reset` |
| Cycle through all presets | Same as `/tuih preset next` (also shows which preset was applied) |
| Cycle through built-in presets / custom presets | Same as `/tuih preset next builtin` / `custom` |
| Cycle backwards through all / built-in / custom presets | Same as `/tuih preset prev [builtin\|custom]` |
| Preset: explore / questing / social / roleplay / minimal / screenshot | Same as `/tuih preset <name>` |
| Toggle: one per element in the table above | Same as `/tuih toggle <element>` (Questie does nothing without Questie) |
| Keep the window under the mouse visible | Same as `/tuih keepframe pick`, without the wait |
| Open options | Same as `/tuih config` |
| Show help links | Same as `/tuih help` |

These commands have no keybinding and are chat-only: `/tuih on`, `/tuih off`, `/tuih status`, `/tuih reset`, `/tuih diff`, `/tuih set ...`, `/tuih preset save|delete|list` and custom presets.

## Todos

Don't mind this. It's for me, the dev :)
And this is also not a promise.

- Improve readme (descripe commands like diff, add troubleshooting, document quirks, add pictures)
- What happens if the game is restarted with UI hidden?

## Releasing (for the maintainer)

A release is built by GitHub Actions when you push a tag that starts with `v`.

1. Commit and push everything to `main`.
2. Create and push the tag (the tag is the version, for example `v0.2.0`):
   ```
   git tag v0.2.0
   git push origin v0.2.0
   ```

Notes:
- Tags like `v0.2.0-beta1` become pre-releases.
- The tag must be on the latest `main`. If you pushed more commits to `main` after creating the tag, the workflow stops before releasing: pull, delete the tag and create it again.
- If the workflow fails (for example the lint step), fix the problem on `main`, then delete the tag and create it again:
  ```
  git tag -d v0.2.0
  git push origin :refs/tags/v0.2.0
  ```
  If a release was already created, delete it on the GitHub releases page first.
- The `## Interface:` number in the `.toc` is not changed by the workflow. Update it by hand when the game version changes.

## Legal

MIT License (see `LICENSE` in the repository root. Release zips contain it as `LICENSE.txt` inside the addon folder).

The license only requires keeping the license notice. On top of that I would appreciate credit if you modify or redistribute this addon :) This is a courtesy request, not a license condition.
