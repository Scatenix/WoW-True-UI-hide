-- Presets: built-in and custom presets, reset
local _, ns = ...

function ns.resetState()
  ns.state.presetCurrent = nil
  TUIHDB.keep = {}
  TUIHDB.combatShow = ns.COMBAT_SHOW_DEFAULT
  ns.userSetAll(true)
  ns.setMouselook(false)  -- back to normal also means a visible cursor
end

-- Finds a preset by name, ignoring case. Returns the stored name, the preset
-- and whether it is a built-in one. Built-in names are lowercase.
function ns.findPreset(name)
  name = tostring(name or "")
  local lower = name:lower()
  if ns.builtin[lower] then return lower, ns.builtin[lower], true end
  if TUIHDB.presets[name] then return name, TUIHDB.presets[name], false end
  for k, p in pairs(TUIHDB.presets) do
    if k:lower() == lower then return k, p, false end
  end
end

-- silent: the caller reports the result itself (preset cycling)
function ns.applyPreset(name, silent)
  local p
  name, p = ns.findPreset(name)
  if not p then return false end
  TUIHDB.keep = ns.copy(p.keep)
  -- Only presets that specify the combat option change it
  if p.combat ~= nil then TUIHDB.combatShow = p.combat end
  TUIHDB.playerNames = p.players or 0
  TUIHDB.enemyNames = p.enemies or 0
  ns.userSetAll(false)
  ns.syncPlates()
  ns.state.presetCurrent = name
  if not silent then ns.notify("Preset: " .. name, "preset") end
  return true
end

-- Used by the settings panel: only changes the settings (kept elements and
-- the combat option), does not hide the UI and leaves the game settings alone
function ns.applyPresetSettings(name)
  local p
  name, p = ns.findPreset(name)
  if not p then return false end
  TUIHDB.keep = ns.copy(p.keep)
  if p.combat ~= nil then TUIHDB.combatShow = p.combat end
  TUIHDB.playerNames = p.players or 0
  TUIHDB.enemyNames = p.enemies or 0
  ns.state.presetCurrent = name
  ns.info("Preset settings: " .. name .. " (the UI stays as it is)", "preset")
  return true
end

-- Custom preset names, sorted (ignoring case)
function ns.customPresetList()
  local mine = {}
  for k in pairs(TUIHDB.presets) do mine[#mine + 1] = k end
  table.sort(mine, function(a, b)
    local la, lb = a:lower(), b:lower()
    if la ~= lb then return la < lb end
    return a < b
  end)
  return mine
end

-- Presets in a stable order. kind: "builtin", "custom" or nil (all:
-- built-in first, then custom ones by name)
function ns.presetList(kind)
  local list = {}
  if kind ~= "custom" then
    for _, name in ipairs(ns.presetOrder) do list[#list + 1] = name end
  end
  if kind ~= "builtin" then
    for _, name in ipairs(ns.customPresetList()) do list[#list + 1] = name end
  end
  return list
end

-- Apply the next preset of the list (see presetList), wrapping around. The
-- position is the preset applied last. If it is not in this list (or was
-- deleted), forwards starts with the first preset, backwards with the last.
function ns.cyclePreset(kind, step)
  step = step or 1  -- 1 = next, -1 = previous
  local list = ns.presetList(kind)
  if #list == 0 then
    ns.log("You have no custom presets. Save one with /tuih preset save <name>.", "preset")
    return
  end
  local pos
  for i, name in ipairs(list) do
    if name == ns.state.presetCurrent then pos = i break end
  end
  local nextPos
  if pos then
    nextPos = (pos - 1 + step) % #list + 1
  else
    nextPos = step > 0 and 1 or #list
  end
  local name = list[nextPos]
  if ns.applyPreset(name, true) then
    ns.notify("Preset: " .. name .. " (" .. nextPos .. "/" .. #list .. ")", "preset")
  end
end

function ns.toggleWhisperChat()
  TUIHDB.whisperChat = not TUIHDB.whisperChat
  ns.log("Chat on whisper while hidden: " .. (TUIHDB.whisperChat and "on" or "off"), "toggle")
end

function ns.toggleToasts()
  TUIHDB.toasts = not TUIHDB.toasts
  if not TUIHDB.toasts then ns.clearToast() end
  ns.log("On-screen messages: " .. (TUIHDB.toasts and "on" or "off"), "toggle")
end

function ns.reset()
  ns.resetState()
  TUIHDB.saved = nil
  ns.log("Reset to normal. Saved state cleared.", "toggle")
end

-- Nuclear option: put the game back to normal if we are in hide mode, then
-- delete ALL addon data and start with a fresh database. Nothing is deleted
-- if the game settings could not be restored (data is still needed for that).
function ns.wipeAll()
  if InCombatLockdown() then
    ns.error("Not possible in combat. Try again after combat.")
    return false
  end
  local active = TUIHDB.saved ~= nil or not UIParent:IsShown() or ns.hasDetached()
    or ns.state.pending ~= nil or ns.state.autoShown or ns.state.peek.mode ~= nil
  if active then
    ns.userSetAll(true)
    ns.setMouselook(false)
    if TUIHDB.saved ~= nil then
      ns.error("Could not restore your game settings. Nothing was deleted.")
      return false
    end
  end
  for k in pairs(TUIHDB) do TUIHDB[k] = nil end
  ns.initDB()
  local st = ns.state
  st.presetCurrent = nil
  st.pending, st.autoShown, st.autoStage, st.autoEnemies, st.needsSync = nil, false, nil, nil, false
  if ns.refreshMinimap then ns.refreshMinimap() end
  if ns.refreshOptions then ns.refreshOptions() end
  if ns.updateIndicator then ns.updateIndicator() end
  ns.log("All data deleted. Fresh defaults are active.")
  return true
end

-- Names that cannot be used for custom presets: they are subcommands
local RESERVED_NAMES = { save = true, delete = true, list = true, next = true, cycle = true, prev = true, previous = true }
local MAX_NAME_LENGTH = 24

-- /tuih preset [<name> | save <name> | delete <name> | list]
-- Save the current state as a custom preset. Returns true on success.
function ns.savePreset(name)
  name = name or ""  -- the case is kept as typed
  if name == "" then
    ns.error("Enter a name for the preset.", "preset")
    return false
  end
  if ns.builtin[name:lower()] or RESERVED_NAMES[name:lower()] then
    ns.error("That name is reserved (built-in preset or subcommand).", "preset")
    return false
  end
  if name:find("%s") then
    ns.error("Preset names cannot contain spaces. Use - or _ instead.", "preset")
    return false
  end
  if #name > MAX_NAME_LENGTH or not name:match("^[%w_%-]+$") then
    ns.error("Preset names may use letters, digits, - and _ (max " .. MAX_NAME_LENGTH .. " characters).", "preset")
    return false
  end
  local existing = ns.findPreset(name)  -- same name in another case: replace it
  if existing then TUIHDB.presets[existing] = nil end
  TUIHDB.presets[name] = {
    keep = ns.copy(TUIHDB.keep),
    combat = TUIHDB.combatShow and true or false,
    players = TUIHDB.playerNames or 0,
    enemies = TUIHDB.enemyNames or 0,
  }
  ns.log("Preset saved: " .. name .. " (current keep settings and name settings)", "preset")
  if ns.refreshOptions then ns.refreshOptions() end
  return true
end

function ns.deletePreset(name)
  local found, _, isBuiltin = ns.findPreset(name)
  if found and not isBuiltin then
    TUIHDB.presets[found] = nil
    ns.log("Preset deleted: " .. found, "preset")
    if ns.refreshOptions then ns.refreshOptions() end
    return true
  end
  ns.error("No custom preset named " .. name, "preset")
  return false
end

function ns.presetCommand(arg)
  -- arg keeps the case as typed (custom preset names are case-preserving)
  -- For save and delete everything after the word is the name, so a name with
  -- spaces is rejected instead of being cut off at the first space
  local sub, rest = arg:match("^(%S*)%s*(.-)%s*$")
  local name = rest:match("^(%S*)") or ""
  local word, kind = sub:lower(), name:lower()
  if word == "save" and rest ~= "" then
    ns.savePreset(rest)
  elseif word == "delete" and rest ~= "" then
    ns.deletePreset(rest)
  elseif word == "next" or word == "cycle" then
    -- /tuih preset next [builtin | custom]
    ns.cyclePreset((kind == "builtin" or kind == "custom") and kind or nil, 1)
  elseif word == "prev" or word == "previous" then
    ns.cyclePreset((kind == "builtin" or kind == "custom") and kind or nil, -1)
  elseif word == "" or word == "list" then
    ns.log("Built-in: " .. table.concat(ns.presetOrder, ", "), "preset")
    local mine = ns.customPresetList()
    ns.log("Custom: " .. (#mine > 0 and table.concat(mine, ", ") or "none"), "preset")
  elseif not ns.applyPreset(sub) then
    ns.log("Unknown preset: " .. sub, "preset")
  end
end
