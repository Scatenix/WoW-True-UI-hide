-- Peek: hold a key to show/hide the UI; screenshot without UI
local _, ns = ...

-- Hold to show the UI while it is hidden
function ns.peekShow(keystate)
  local peek = ns.state.peek
  if keystate == "down" then
    if not UIParent:IsShown() and not peek.mode then
      peek.mode = "show"
      peek.stage = ns.getStage()
      ns.setAll(true)
    end
  elseif peek.mode == "show" then
    peek.mode = nil
    ns.setAll(false)
    ns.setStage(peek.stage or 0)
  end
end

-- Hold to hide the UI while it is visible
function ns.peekHide(keystate)
  local peek = ns.state.peek
  if keystate == "down" then
    if UIParent:IsShown() and not peek.mode then
      peek.mode = "hide"
      ns.setAll(false)
    end
  elseif peek.mode == "hide" then
    peek.mode = nil
    ns.setAll(true)
  end
end

-- Hide everything (also kept elements), take a screenshot, restore
function ns.shot()
  local st = ns.state
  if st.shotBusy then return end
  if not (C_Timer and C_Timer.After) then
    ns.log("C_Timer is not available, cannot take a screenshot.")
    return
  end
  st.shotBusy = true
  local wasShown = UIParent:IsShown()
  local plates = GetCVar("nameplateShowEnemies")
  st.shotMode = true
  if wasShown then
    ns.setAll(false)
  else
    ns.sync()
    if not InCombatLockdown() then pcall(SetCVar, "nameplateShowEnemies", "0") end
  end
  C_Timer.After(0.4, function()
    Screenshot()
    C_Timer.After(0.6, function()
      st.shotMode = false
      if wasShown then
        ns.setAll(true)
      else
        ns.sync()
        if plates and not InCombatLockdown() then
          pcall(SetCVar, "nameplateShowEnemies", plates)
        end
      end
      st.shotBusy = false
    end)
  end)
end