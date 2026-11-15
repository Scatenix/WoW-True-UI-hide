-- Combat: optionally show the UI while in combat
local _, ns = ...

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
  if not TUIHDB then return end
  local st = ns.state
  if event == "PLAYER_REGEN_DISABLED" then
    if TUIHDB.combatShow and not UIParent:IsShown() and not st.peek.mode and not st.shotBusy then
      st.autoShown = true
      st.autoStage = ns.getStage()
      ns.setAll(true, true)
    end
  else
    if st.autoShown then
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