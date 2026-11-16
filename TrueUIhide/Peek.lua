-- Peek: hold a key to show/hide the UI; screenshot without UI
local _, ns = ...

-- End a running peek and put the UI back the way it was before it.
-- Also used when a key-up got lost (alt-tab, dialog), so peek cannot get stuck.
function ns.endPeek()
  local peek = ns.state.peek
  if peek.mode == "show" then
    peek.mode = nil
    ns.setAll(false)
    ns.setStage(peek.stage or 0)
  elseif peek.mode == "hide" then
    peek.mode = nil
    ns.setAll(true)
  end
end

-- Hold to show the UI while it is hidden
function ns.peekShow(keystate)
  local peek = ns.state.peek
  if ns.state.shotBusy then return end
  if keystate == "down" then
    if peek.mode then ns.endPeek() end  -- stale peek: its key-up never came
    if not UIParent:IsShown() then
      peek.mode = "show"
      peek.stage = ns.getStage()
      ns.setAll(true)
    end
  elseif peek.mode == "show" then
    ns.endPeek()
  end
end

-- Hold to hide the UI while it is visible
function ns.peekHide(keystate)
  local peek = ns.state.peek
  if ns.state.shotBusy then return end
  if keystate == "down" then
    if peek.mode then ns.endPeek() end  -- stale peek: its key-up never came
    if UIParent:IsShown() then
      peek.mode = "hide"
      ns.setAll(false)
    end
  elseif peek.mode == "hide" then
    ns.endPeek()
  end
end

-- Safety net: a peek never survives loading screens (combat start: Combat.lua)
local peekEv = CreateFrame("Frame")
peekEv:RegisterEvent("PLAYER_ENTERING_WORLD")
peekEv:SetScript("OnEvent", function() ns.endPeek() end)

-- End a running screenshot: stop its timers and put everything back.
-- Safe to call at any time; does nothing when no screenshot is running.
local function finishShot()
  local st = ns.state
  local ctx = st.shotCtx
  if not ctx then return end
  if ctx.timer then ctx.timer:Cancel() end
  st.shotCtx, st.shotMode, st.shotBusy = nil, false, false
  if ctx.wasShown then
    ns.setAll(true)
    if not UIParent:IsShown() then
      -- Combat blocked showing the UI: do it as soon as combat ends
      st.pending = "show"
      ns.log("Combat blocked showing the UI. It will be shown when combat ends.")
    end
  else
    ns.sync()  -- defers itself during combat and finishes afterwards
    if ctx.plates and not InCombatLockdown() then
      ns.setCVar("nameplateShowEnemies", ctx.plates)
    end
  end
end

-- Cancel a running screenshot (combat started, or the player did something else)
function ns.abortShot(msg)
  if not ns.state.shotCtx then return end
  finishShot()
  if msg then ns.log(msg) end
end

-- Hide everything (also kept elements), take a screenshot, restore
function ns.shot()
  local st = ns.state
  if st.shotBusy then return end
  if not (C_Timer and C_Timer.NewTimer) then
    ns.log("C_Timer is not available, cannot take a screenshot.")
    return
  end
  local ctx = {
    wasShown = UIParent:IsShown(),
    plates = GetCVar("nameplateShowEnemies"),
  }
  st.shotCtx, st.shotBusy, st.shotMode = ctx, true, true
  if ctx.wasShown then
    ns.setAll(false)
  else
    ns.sync()
    if not InCombatLockdown() then ns.setCVar("nameplateShowEnemies", "0") end
  end
  ctx.timer = C_Timer.NewTimer(TUIHDB.shotBefore or ns.SHOT_BEFORE_DEFAULT, function()
    Screenshot()
    ctx.timer = C_Timer.NewTimer(TUIHDB.shotAfter or ns.SHOT_AFTER_DEFAULT, function()
      ctx.timer = nil
      finishShot()
    end)
  end)
end
