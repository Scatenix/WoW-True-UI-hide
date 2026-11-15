-- Options: panel under Esc > Options > AddOns
local _, ns = ...

local cfg, category
local refreshers = {}

local function refreshAll()
  for _, r in ipairs(refreshers) do r() end
end

local function buildConfig()
  if cfg then return end
  cfg = CreateFrame("Frame", "TUIHOptionsPanel")
  cfg.name = "True UI hide"

  local title = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("|cffa335eeTrue UI hide|r")

  local function heading(y, text)
    local fs = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 20, y)
    fs:SetText(text)
  end

  local function addCheck(y, text, get, set)
    local cb = CreateFrame("CheckButton", nil, cfg, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    cb:SetSize(24, 24)
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    fs:SetText(text)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    refreshers[#refreshers + 1] = function() cb:SetChecked(get()) end
  end

  heading(-52, "Keep visible while the UI is hidden:")
  local y = -74
  for _, e in ipairs(ns.keepList) do
    if ns.available(e) then
      local key = e.key
      addCheck(y, e.label,
        function() return TUIHDB.keep[key] end,
        function(v) ns.setKeep(key, v) end)
      y = y - 26
    end
  end

  heading(y - 14, "Options:")
  addCheck(y - 36, "Show the UI during combat",
    function() return TUIHDB.combatShow end,
    function(v) TUIHDB.combatShow = v end)
    
    local warn = cfg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warn:SetPoint("TOPLEFT", 44, y - 62)
    warn:SetWidth(420)
    warn:SetJustifyH("LEFT")
    warn:SetTextColor(1, 0.6, 0.2)
    warn:SetText("Warning: " .. ns.COMBAT_WARNING)
  
    local py = y - 116
  heading(py, "Presets:")
  local function addButton(i, text, onClick)
    local b = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    b:SetSize(120, 24)
    local col = (i - 1) % 3
    local row = math.floor((i - 1) / 3)
    b:SetPoint("TOPLEFT", 20 + col * 130, py - 24 - row * 30)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
  end
  for i, name in ipairs(ns.presetOrder) do
    addButton(i, name:sub(1, 1):upper() .. name:sub(2), function()
      ns.applyPreset(name)
      refreshAll()
    end)
  end
  addButton(#ns.presetOrder + 1, "Reset", function()
    ns.reset()
    refreshAll()
  end)

  -- Checkboxes always reflect the current settings when the panel opens
  cfg:SetScript("OnShow", refreshAll)
end

-- Registers the panel with whichever options system the client has
local function registerConfig()
  buildConfig()
  if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(cfg, cfg.name)
    Settings.RegisterAddOnCategory(category)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(cfg)
  end
end

function ns.openConfig()
  if category and Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(category:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory and cfg then
    -- Called twice on purpose: the first call often only opens the frame
    InterfaceOptionsFrame_OpenToCategory(cfg)
    InterfaceOptionsFrame_OpenToCategory(cfg)
  else
    ns.log("Options panel is not available in this client.")
  end
end

ns.onLogin[#ns.onLogin + 1] = registerConfig