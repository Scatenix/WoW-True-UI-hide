-- Binds: keybinding labels and the global functions used by Bindings.xml
local _, ns = ...

BINDING_HEADER_TUIH = "TUIH"
BINDING_NAME_TUIH_TOGGLE = "Toggle UI and names"
BINDING_NAME_TUIH_PLAYERS = "Cycle player names"
BINDING_NAME_TUIH_PEEK = "Peek: show UI while held"
BINDING_NAME_TUIH_PEEK_HIDE = "Peek: hide UI while held"
BINDING_NAME_TUIH_SHOT = "Screenshot without UI"
BINDING_NAME_TUIH_MOUSELOOK = "Mouselook (right-click style)"
BINDING_NAME_TUIH_CONFIG = "Open options"
BINDING_NAME_TUIH_HELP = "Show help link"
BINDING_NAME_TUIH_PRESET_NORMAL = "Preset: normal"
BINDING_NAME_TUIH_PRESET_EXPLORE = "Preset: explore"
BINDING_NAME_TUIH_PRESET_SOCIAL = "Preset: social"
BINDING_NAME_TUIH_PRESET_IMMERSIVE = "Preset: immersive"
BINDING_NAME_TUIH_PRESET_SCREENSHOT = "Preset: screenshot"

-- One "Keep: ..." binding per keepable element
for _, e in ipairs(ns.keepList) do
  _G["BINDING_NAME_TUIH_KEEP_" .. e.key:upper()] = "Keep: " .. e.label
end

-- Globals called from Bindings.xml
function TUIH_Toggle() ns.toggle() end
function TUIH_Players() ns.cyclePlayers() end
function TUIH_Peek(keystate) ns.peekShow(keystate) end
function TUIH_PeekHide(keystate) ns.peekHide(keystate) end
function TUIH_Shot() ns.shot() end
function TUIH_Mouselook() ns.toggleMouselook() end
function TUIH_Config() ns.openConfig() end
function TUIH_Help() ns.showHelp() end
function TUIH_Preset(name) ns.applyPreset(name) end
function TUIH_Keep(key) ns.toggleKeep(key) end