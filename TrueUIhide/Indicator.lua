-- Indicator: a small red dot that shows up when the addon is in an
-- inconsistent state: the UI is visible again (for example the game showed
-- it when Escape was pressed), but our hide settings are still applied
-- (saved CVars not restored, frames still detached).
-- It is tiny and opaque, lives on WorldFrame (so it also works while UIParent
-- is hidden) and follows the real state, so it cannot stay on by itself.
local _, ns = ...

local dot

local function unstable()
  if not TUIHDB or not TUIHDB.indicator or ns.state.shotBusy then return false end
  return UIParent:IsShown() and (TUIHDB.saved ~= nil or ns.hasDetached())
end

local function build()
  dot = CreateFrame("Button", "TUIHIndicator", WorldFrame)
  dot:SetSize(20, 20)
  dot:SetFrameStrata("FULLSCREEN_DIALOG")
  -- Near the screen center, slightly left and up: hard to miss
  dot:SetPoint("CENTER", WorldFrame, "CENTER", -160, 120)
  dot:Hide()

  local border = dot:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints()
  border:SetColorTexture(1, 1, 1, 1)
  local fill = dot:CreateTexture(nil, "ARTWORK")
  fill:SetPoint("TOPLEFT", 2, -2)
  fill:SetPoint("BOTTOMRIGHT", -2, 2)
  fill:SetColorTexture(0.9, 0.1, 0.1, 1)

  dot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  dot:SetScript("OnClick", function(_, button)
    if InCombatLockdown() then
      ns.log("The game blocks this in combat. Try again after combat.")
      return
    end
    if button == "RightButton" then ns.userSetAll(false) else ns.userSetAll(true) end
  end)
  dot:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:AddLine("True UI Hide", 0.64, 0.21, 0.93)
    GameTooltip:AddLine("The UI is visible, but hide settings are still applied.", 1, 1, 1, true)
    GameTooltip:AddLine("True UI Hide is in an unstable state!.", 1, 1, 1, true)
    GameTooltip:AddLine("Left-click: restore everything", 1, 0.82, 0)
    GameTooltip:AddLine("Right-click: hide the UI again", 1, 0.82, 0)
    GameTooltip:Show()
  end)
  dot:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function ns.updateIndicator()
  if not dot then build() end
  if unstable() then
    -- WorldFrame and UIParent can have different scales; keep a constant size
    dot:SetScale(UIParent:GetEffectiveScale() / WorldFrame:GetEffectiveScale())
    dot:Show()
  else
    dot:Hide()
  end
end

-- Check one frame later, after the code that changed the state has finished
local function schedule()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, ns.updateIndicator)
  else
    ns.updateIndicator()
  end
end

UIParent:HookScript("OnShow", schedule)
UIParent:HookScript("OnHide", schedule)
hooksecurefunc(ns, "setAll", schedule)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:SetScript("OnEvent", schedule)

function ns.toggleIndicator()
  TUIHDB.indicator = not TUIHDB.indicator
  ns.updateIndicator()
  ns.log("Warning dot: " .. (TUIHDB.indicator and "on" or "off"), "toggle")
end
