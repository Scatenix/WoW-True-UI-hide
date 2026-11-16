-- Presets: built-in and custom presets, reset
local _, ns = ...

function ns.resetState()
  TUIHDB.keep = {}
  TUIHDB.combatShow = ns.COMBAT_SHOW_DEFAULT
  ns.userSetAll(true)
  ns.setMouselook(false)  -- back to normal also means a visible cursor
end

function ns.applyPreset(name)
  name = (name or ""):lower()
  if name == "normal" then
    ns.resetState()
    ns.info("Preset: normal", "preset")
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
  ns.info("Preset: " .. name, "preset")
  return true
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
  st.pending, st.autoShown, st.autoStage, st.needsSync = nil, false, nil, false
  if ns.refreshMinimap then ns.refreshMinimap() end
  if ns.refreshOptions then ns.refreshOptions() end
  ns.log("All data deleted. Fresh defaults are active.")
  return true
end

-- Names that cannot be used for custom presets: they are subcommands
local RESERVED_NAMES = { save = true, delete = true, list = true, normal = true }
local MAX_NAME_LENGTH = 24

-- /tuih preset [<name> | save <name> | delete <name> | list]
function ns.presetCommand(arg)
  local sub, name = arg:match("^(%S*)%s*(%S*)")
  if sub == "save" and name ~= "" then
    if ns.builtin[name] or RESERVED_NAMES[name] then
      ns.log("That name is reserved (built-in preset or subcommand).", "preset")
      return
    end
    if #name > MAX_NAME_LENGTH or not name:match("^[%w_%-]+$") then
      ns.log("Preset names may use letters, digits, - and _ (max " .. MAX_NAME_LENGTH .. " characters).", "preset")
      return
    end
    TUIHDB.presets[name] = {
      keep = ns.copy(TUIHDB.keep),
      combat = TUIHDB.combatShow and true or false,
      players = ns.getStage(),
    }
    ns.log("Preset saved: " .. name .. " (current keep settings and player-name stage)", "preset")
  elseif sub == "delete" and name ~= "" then
    if TUIHDB.presets[name] then
      TUIHDB.presets[name] = nil
      ns.log("Preset deleted: " .. name, "preset")
    else
      ns.log("No custom preset named " .. name, "preset")
    end
  elseif sub == "" or sub == "list" then
    ns.log("Built-in: " .. table.concat(ns.presetOrder, ", "), "preset")
    local mine = {}
    for k in pairs(TUIHDB.presets) do mine[#mine + 1] = k end
    table.sort(mine)
    ns.log("Custom: " .. (#mine > 0 and table.concat(mine, ", ") or "none"), "preset")
  elseif not ns.applyPreset(sub) then
    ns.log("Unknown preset: " .. sub, "preset")
  end
end