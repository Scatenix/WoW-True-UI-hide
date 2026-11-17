-- Diag: find the CVar of a menu option, show current settings
local _, ns = ...

local baseline

local function snapshotAll()
  local list = ns.getAllCommands()
  if not list then return nil end
  local t = {}
  for _, info in ipairs(list) do
    local n = info.command or info.name
    if n then
      local v = GetCVar(n)
      if v ~= nil then t[n] = v end
    end
  end
  return t
end

function ns.diff()
  local now = snapshotAll()
  if not now then ns.log("Console command list is not available.") return end
  if not baseline then
    baseline = now
    ns.log("Baseline saved. Change an option in the menu, then run /tuih diff again.")
    return
  end
  local n = 0
  for k, v in pairs(now) do
    if baseline[k] ~= v then
      n = n + 1
      ns.log(k .. ": " .. tostring(baseline[k]) .. " -> " .. v)
    end
  end
  if n == 0 then ns.log("No changes found.") end
  baseline = nil
end

function ns.status()
  for _, e in ipairs(ns.keepList) do
    if ns.available(e) then
      ns.log(e.label .. ": " .. (TUIHDB.keep[e.key] and "kept" or "hidden"))
    end
  end
  local own = ns.customFrameList()
  for i, n in ipairs(own) do own[i] = n .. (ns.customKept(n) and " (kept)" or " (off)") end
  ns.log("Your own windows: " .. (#own > 0 and table.concat(own, ", ") or "none"))
  ns.log("Show UI in combat: " .. (TUIHDB.combatShow and "on" or "off"))
  ns.log("Show UI if combat starts during a screenshot: " .. (TUIHDB.shotCombatShow and "on" or "off"))
  ns.log("Mouselook while the UI is hidden: " .. (TUIHDB.mouselookAuto and "on" or "off"))
  ns.log("Player names while hidden: " .. ns.stageNames[TUIHDB.playerNames or 0])
  ns.log("Chat message when cycling presets: " .. (TUIHDB.cycleMessage and "on" or "off"))
  ns.log("Warning dot: " .. (TUIHDB.indicator and "on" or "off"))
  ns.log("Events in chat: " .. (TUIHDB.verbose and "on" or "off"))
end
