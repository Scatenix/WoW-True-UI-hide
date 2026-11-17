-- Actions: show/hide, keep toggles, player name cycle
local _, ns = ...

function ns.setAll(show, quiet)
  if show then ns.restore(quiet) else ns.hideAll() end
  ns.applyUI(show)
  -- Player names while hidden follow the saved setting (default: none)
  if not show then ns.setStage(TUIHDB.playerNames or 0) end
end

-- Used for everything the player triggers directly
function ns.userSetAll(show)
  if ns.state.shotBusy then ns.abortShot() end  -- the player's own action wins
  ns.state.pending = nil
  ns.state.autoShown = false
  ns.state.peek.mode = nil
  ns.setAll(show)
end

function ns.setKeep(key, value)
  TUIHDB.keep[key] = value or nil
  ns.sync()
  ns.syncPlates()
end

-- Turns every element and every own window on, or all of them off when
-- everything is already on. Presets, other settings and the UI stay as they are.
function ns.toggleKeepAll()
  local keys, all = {}, true
  for _, e in ipairs(ns.keepList) do
    if ns.available(e) then
      keys[#keys + 1] = e.key
      if not TUIHDB.keep[e.key] then all = false end
    end
  end
  for _, name in ipairs(ns.customFrameList()) do
    keys[#keys + 1] = "frame:" .. name
    if not TUIHDB.keep["frame:" .. name] then all = false end
  end
  for _, k in ipairs(keys) do TUIHDB.keep[k] = (not all) or nil end
  ns.state.presetCurrent = nil
  ns.sync()
  ns.syncPlates()
  ns.info("Keep everything: " .. (all and "off" or "on"), "toggle")
  if ns.refreshOptions then ns.refreshOptions() end
end

function ns.toggleKeep(key)
  local e = ns.keepByKey[key]
  if not e then return end
  if not ns.available(e) then
    ns.log(e.label .. ": " .. e.requires .. " is not loaded, nothing to do.", "toggle")
    return
  end
  local on = not TUIHDB.keep[key]
  ns.setKeep(key, on)
  ns.info("Keep " .. e.label:lower() .. ": " .. (on and "on" or "off"), "toggle")
end

-- Player names while the UI is hidden: 0 none, 1 own only, 2 others only,
-- 3 own + others. A saved setting; applied right away when already hidden.
function ns.setPlayerNames(i)
  i = tonumber(i) or 0
  if i < 0 or i > 3 then i = 0 end
  TUIHDB.playerNames = i
  if not UIParent:IsShown() then
    ns.setStage(i)
    ns.hidePlayerPlates()
  end
end

-- Cycle: none -> own only -> others only -> own + others -> none
function ns.cyclePlayers()
  local i = ((TUIHDB.playerNames or 0) + 1) % 4
  ns.setPlayerNames(i)
  ns.info(ns.stageNames[i] .. (UIParent:IsShown() and " (applies when the UI is hidden)" or ""), "players")
end

function ns.toggle()
  local show = not UIParent:IsShown()
  ns.userSetAll(show)
  ns.info("UI " .. (show and "on" or "off"), "toggle")
end
