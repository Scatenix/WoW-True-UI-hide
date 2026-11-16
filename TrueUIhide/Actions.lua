-- Actions: show/hide, keep toggles, player name cycle
local _, ns = ...

function ns.setAll(show, quiet)
  if show then ns.restore(quiet) else ns.hideAll() end
  ns.applyUI(show)
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

-- Cycle: none -> own only -> others only -> own + others -> none
function ns.cyclePlayers()
  local i = (ns.getStage() + 1) % 4
  ns.setStage(i)
  ns.hidePlayerPlates()
  ns.info(ns.stageNames[i], "players")
end

function ns.toggle()
  local show = not UIParent:IsShown()
  ns.userSetAll(show)
  ns.info("UI " .. (show and "on" or "off"), "toggle")
end
