-- MinimapButton: small icon on the minimap border that opens the settings.
-- Drag it to move it around the minimap; it can be hidden in the settings.
local _, ns = ...

local button
local DEFAULT_ANGLE = 215  -- degrees, lower left

local function updatePosition()
  if not button then return end
  local angle = math.rad(TUIHDB.minimapAngle or DEFAULT_ANGLE)
  local radius = (Minimap:GetWidth() / 2) + 5
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

-- While dragging: follow the cursor's direction from the minimap center
local function onDragUpdate()
  local cx, cy = Minimap:GetCenter()
  local scale = Minimap:GetEffectiveScale()
  local mx, my = GetCursorPosition()
  TUIHDB.minimapAngle = math.deg(math.atan2(my / scale - cy, mx / scale - cx))
  updatePosition()
end

local function build()
  button = CreateFrame("Button", "TUIHMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("AnyUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(20, 20)
  bg:SetPoint("TOPLEFT", 7, -5)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(17, 17)
  icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexture("Interface\\Icons\\achievement_zone_stormpeaks_01")
  icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetSize(50, 50)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  button:SetScript("OnClick", function() ns.openConfig() end)
  button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onDragUpdate) end)
  button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("True UI Hide", 0.64, 0.21, 0.93)
    GameTooltip:AddLine("Click: open the settings", 1, 1, 1)
    GameTooltip:AddLine("Drag: move this icon", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function ns.setMinimapIcon(show)
  TUIHDB.minimapIcon = show and true or false
  if not button then return end
  button:SetShown(TUIHDB.minimapIcon)
end

-- Re-read position and visibility from the settings (after a wipe)
function ns.refreshMinimap()
  updatePosition()
  if button then button:SetShown(TUIHDB.minimapIcon) end
end

function ns.toggleMinimapIcon()
  ns.setMinimapIcon(not TUIHDB.minimapIcon)
  ns.log("Minimap icon: " .. (TUIHDB.minimapIcon and "shown" or "hidden"), "toggle")
end

ns.onLogin[#ns.onLogin + 1] = function()
  build()
  updatePosition()
  button:SetShown(TUIHDB.minimapIcon)
end
