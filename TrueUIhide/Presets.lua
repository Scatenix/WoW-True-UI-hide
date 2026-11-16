-- Presets: built-in and custom presets, reset
local _, ns = ...

function ns.resetState()
  ns.state.presetCurrent = "normal"
  TUIHDB.keep = {}
  TUIHDB.combatShow = ns.COMBAT_SHOW_DEFAULT
  ns.userSetAll(true)
  ns.setMouselook(false)  -- back to normal also means a visible cursor
end

-- silent: the caller reports the result itself (preset cycling)
function ns.applyPreset(name, silent)
  name = (name or ""):lower()
  if name == "normal" then
    ns.resetState()
    if not silent then ns.info("Preset: normal", "preset") end
    return true
  end
  local p = ns.builtin[name] or TUIHDB.presets[name]
  if not p then return false end
  TUIHDB.keep = ns.copy(p.keep)
  -- Only presets that specify the combat option change it
  if p.combat ~= nil then TUIHDB.combatShow = p.combat end
  ns.userSetAll(false)
  ns.setStage(p.players or 0)
  ns.syncPlates()
  ns.state.presetCurrent = name
  if not silent then ns.info("Preset: " .. name, "preset") end
  return true
end

-- Used by the settings panel: only changes the settings (kept elements and
-- the combat option), does not hide the UI and leaves the game settings alone
function ns.applyPresetSettings(name)
  name = (name or ""):lower()
  if name == "normal" then
    TUIHDB.keep = {}
    TUIHDB.combatShow = ns.COMBAT_SHOW_DEFAULT
    ns.state.presetCurrent = "normal"
    return true
  end
  local p = ns.builtin[name] or TUIHDB.presets[name]
  if not p then return false end
  TUIHDB.keep = ns.copy(p.keep)
  if p.combat ~= nil then TUIHDB.combatShow = p.combat end
  ns.state.presetCurrent = name
  ns.info("Preset settings: " .. name .. " (the UI stays as it is)", "preset")
  return true
end

-- Custom preset names, sorted
function ns.customPresetList()
  local mine = {}
  for k in pairs(TUIHDB.presets) do mine[#mine + 1] = k end
  table.sort(mine)
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
-- deleted), "all" and "builtin" continue after "normal", "custom" starts
-- with its first preset.
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
  elseif kind == "custom" then
    nextPos = step > 0 and 1 or #list
  else
    nextPos = (1 - 1 + step) % #list + 1  -- as if "normal" were the current one
  end
  local name = list[nextPos]
  if ns.applyPreset(name, true) and TUIHDB.cycleMessage then
    ns.log("Preset: " .. name .. " (" .. nextPos .. "/" .. #list .. ")", "preset")
  end
end

function ns.toggleCycleMessage()
  TUIHDB.cycleMessage = not TUIHDB.cycleMessage
  ns.log("Chat message when cycling presets: " .. (TUIHDB.cycleMessage and "on" or "off"), "toggle")
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
    ns.log("Not possible in combat. Try again after combat.")
    return false
  end
  local active = TUIHDB.saved ~= nil or not UIParent:IsShown() or ns.hasDetached()
    or ns.state.pending ~= nil or ns.state.autoShown or ns.state.peek.mode ~= nil
  if active then
    ns.userSetAll(true)
    ns.setMouselook(false)
    if TUIHDB.saved ~= nil then
      ns.log("Could not restore your game settings. Nothing was deleted.")
      return false
    end
  end
  for k in pairs(TUIHDB) do TUIHDB[k] = nil end
  ns.initDB()
  local st = ns.state
  st.presetCurrent = nil
  st.pending, st.autoShown, st.autoStage, st.needsSync = nil, false, nil, false
  if ns.refreshMinimap then ns.refreshMinimap() end
  if ns.refreshOptions then ns.refreshOptions() end
  if ns.updateIndicator then ns.updateIndicator() end
  ns.log("All data deleted. Fresh defaults are active.")
  return true
end

-- Names that cannot be used for custom presets: they are subcommands
local RESERVED_NAMES = { save = true, delete = true, list = true, next = true, cycle = true, prev = true, previous = true, normal = true }
local MAX_NAME_LENGTH = 24

-- /tuih preset [<name> | save <name> | delete <name> | list]
-- Save the current state as a custom preset. Returns true on success.
function ns.savePreset(name)
  name = (name or ""):lower()
  if name == "" then
    ns.log("Enter a name for the preset.", "preset")
    return false
  end
  if ns.builtin[name] or RESERVED_NAMES[name] then
    ns.log("That name is reserved (built-in preset or subcommand).", "preset")
    return false
  end
  if #name > MAX_NAME_LENGTH or not name:match("^[%w_%-]+$") then
    ns.log("Preset names may use letters, digits, - and _ (max " .. MAX_NAME_LENGTH .. " characters).", "preset")
    return false
  end
  TUIHDB.presets[name] = {
    keep = ns.copy(TUIHDB.keep),
    combat = TUIHDB.combatShow and true or false,
    players = ns.getStage(),
  }
  ns.log("Preset saved: " .. name .. " (current keep settings and player-name stage)", "preset")
  if ns.refreshOptions then ns.refreshOptions() end
  return true
end

function ns.deletePreset(name)
  if TUIHDB.presets[name] then
    TUIHDB.presets[name] = nil
    ns.log("Preset deleted: " .. name, "preset")
    if ns.refreshOptions then ns.refreshOptions() end
    return true
  end
  ns.log("No custom preset named " .. name, "preset")
  return false
end

function ns.presetCommand(arg)
  local sub, name = arg:match("^(%S*)%s*(%S*)")
  if sub == "save" and name ~= "" then
    ns.savePreset(name)
  elseif sub == "delete" and name ~= "" then
    ns.deletePreset(name)
  elseif sub == "next" or sub == "cycle" then
    -- /tuih preset next [builtin | custom]
    ns.cyclePreset((name == "builtin" or name == "custom") and name or nil, 1)
  elseif sub == "prev" or sub == "previous" then
    ns.cyclePreset((name == "builtin" or name == "custom") and name or nil, -1)
  elseif sub == "" or sub == "list" then
    ns.log("Built-in: " .. table.concat(ns.presetOrder, ", "), "preset")
    local mine = ns.customPresetList()
    ns.log("Custom: " .. (#mine > 0 and table.concat(mine, ", ") or "none"), "preset")
  elseif not ns.applyPreset(sub) then
    ns.log("Unknown preset: " .. sub, "preset")
  end
end
