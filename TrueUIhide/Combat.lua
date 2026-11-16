-- Combat: optionally show the UI while in combat
local _, ns = ...

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
  if not TUIHDB then return end
  local st = ns.state
  if event == "PLAYER_REGEN_DISABLED" then
    -- End a running peek first (its key-up may be lost); the auto-show below
    -- then decides what the UI looks like in combat
    ns.endPeek()
    -- Combat during a screenshot: by default give the UI back right away,
    -- while the game still allows it (this handler runs before the lockdown)
    if st.shotBusy and TUIHDB.shotCombatShow then
      ns.abortShot("Screenshot cancelled: combat started.")
    end
    if TUIHDB.combatShow and not UIParent:IsShown() and not st.peek.mode and not st.shotBusy then
      st.autoShown = true
      st.autoStage = ns.getStage()
      ns.setAll(true, true)
    end
  else
    if st.pending == "show" then
      -- A show that was blocked by combat (e.g. end of a screenshot)
      st.pending = nil
      st.autoShown = false
      ns.setAll(true)
    elseif st.autoShown then
      st.autoShown = false
      ns.setAll(false)
      ns.setStage(st.autoStage or 0)
    end
    if st.needsSync then
      st.needsSync = false
      ns.sync()
      ns.syncPlates()
    end
  end
end)

function ns.toggleCombat()
  TUIHDB.combatShow = not TUIHDB.combatShow
  ns.log("Show UI in combat: " .. (TUIHDB.combatShow and "on" or "off"), "toggle")
  if TUIHDB.combatShow then ns.log(ns.COMBAT_WARNING, "toggle") end
end

function ns.toggleShotCombat()
  TUIHDB.shotCombatShow = not TUIHDB.shotCombatShow
  ns.log("Show the UI if combat starts during a screenshot: " .. (TUIHDB.shotCombatShow and "on" or "off"), "toggle")
  if not TUIHDB.shotCombatShow then ns.log(ns.SHOT_COMBAT_WARNING, "toggle") end
end
