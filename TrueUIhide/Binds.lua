-- Binds: keybinding labels and the global functions used by Bindings.xml
local _, ns = ...

-- Section headers in the key bindings menu
BINDING_HEADER_TUIH = "True UI Hide: Main"
BINDING_HEADER_TUIH_PRESETS = "True UI Hide: Presets"
BINDING_HEADER_TUIH_KEEP = "True UI Hide: Toggle which elements stay visible"
BINDING_HEADER_TUIH_MISC = "True UI Hide: Other"

BINDING_NAME_TUIH_TOGGLE = "Toggle UI and names"
BINDING_NAME_TUIH_PLAYERS = "Cycle player names (own, friendly)"
BINDING_NAME_TUIH_ENEMIES = "Cycle enemy names (players, mobs)"
BINDING_NAME_TUIH_PEEK = "Peek: flip the UI while held"
BINDING_NAME_TUIH_SHOT = "Screenshot without UI"
BINDING_NAME_TUIH_MOUSELOOK = "Mouselook (right-click style)"
BINDING_NAME_TUIH_RESET = "Reset (back to normal)"
BINDING_NAME_TUIH_CONFIG = "Open options"
BINDING_NAME_TUIH_GAMEMENU = "Open or close the game menu (works while the UI is hidden)"
BINDING_NAME_TUIH_KEEPFRAME = "Keep the window under the mouse visible"
BINDING_NAME_TUIH_HELP = "Show help links"
BINDING_NAME_TUIH_PRESET_CYCLE = "Cycle through all presets"
BINDING_NAME_TUIH_PRESET_CYCLE_BUILTIN = "Cycle through built-in presets"
BINDING_NAME_TUIH_PRESET_CYCLE_CUSTOM = "Cycle through custom presets"
BINDING_NAME_TUIH_PRESET_BACK = "Cycle backwards through all presets"
BINDING_NAME_TUIH_PRESET_BACK_BUILTIN = "Cycle backwards through built-in presets"
BINDING_NAME_TUIH_PRESET_BACK_CUSTOM = "Cycle backwards through custom presets"
BINDING_NAME_TUIH_PRESET_EXPLORE = "Preset: explore"
BINDING_NAME_TUIH_PRESET_QUESTING = "Preset: questing"
BINDING_NAME_TUIH_PRESET_SOCIAL = "Preset: social"
BINDING_NAME_TUIH_PRESET_ROLEPLAY = "Preset: roleplay"
BINDING_NAME_TUIH_PRESET_MINIMAL = "Preset: minimal"
BINDING_NAME_TUIH_PRESET_SCREENSHOT = "Preset: screenshot"

-- One "Toggle: ..." binding per keepable element
for _, e in ipairs(ns.keepList) do
  _G["BINDING_NAME_TUIH_KEEP_" .. e.key:upper()] = "Toggle: " .. e.label
end

-- Globals called from Bindings.xml
function TUIH_Toggle() ns.toggle() end
function TUIH_Players() ns.cyclePlayers() end
function TUIH_Enemies() ns.cycleEnemies() end
function TUIH_Peek(keystate) ns.peek(keystate) end
function TUIH_Shot() ns.shot() end
function TUIH_Mouselook() ns.toggleMouselook() end
function TUIH_Reset() ns.reset() end
function TUIH_Config() ns.openConfig() end
function TUIH_GameMenu() ns.openGameMenu() end
function TUIH_Help() ns.showHelp() end
function TUIH_PresetCycle(kind, step) ns.cyclePreset(kind, step) end
function TUIH_Preset(name) ns.applyPreset(name) end
function TUIH_Keep(key) ns.toggleKeep(key) end
function TUIH_KeepFrame() ns.pickFrame() end
