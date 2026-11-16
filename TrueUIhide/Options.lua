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
  cfg.name = "True UI Hide"

  -- Everything lives in a scrollable area, so the panel can grow
  local scroll = CreateFrame("ScrollFrame", "TUIHOptionsScroll", cfg, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, -4)
  scroll:SetPoint("BOTTOMRIGHT", -28, 4)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(560, 900)
  scroll:SetScrollChild(content)

  local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("|cffa335eeTrue UI Hide|r")

  local function heading(y, text)
    local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 20, y)
    fs:SetText(text)
  end

  local function addCheck(y, text, get, set)
    local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    cb:SetSize(24, 24)
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    fs:SetText(text)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    refreshers[#refreshers + 1] = function() cb:SetChecked(get()) end
  end

  -- Small text under a checkbox; warnings are orange, infos gray
  local function addNote(y, text, warning, plain)
    local fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", 44, y)
    fs:SetWidth(420)
    fs:SetJustifyH("LEFT")
    if plain then
      if warning then fs:SetTextColor(1, 0.6, 0.2) else fs:SetTextColor(0.8, 0.8, 0.8) end
      fs:SetText(text)
    elseif warning then
      fs:SetTextColor(1, 0.6, 0.2)
      fs:SetText("Warning: " .. text)
    else
      fs:SetTextColor(0.8, 0.8, 0.8)
      fs:SetText("Info: " .. text)
    end
  end

  -- Slider with a live value in its title; values are rounded to one decimal
  local sliderCount = 0
  local function addSlider(y, label, min, max, step, get, set)
    sliderCount = sliderCount + 1
    local name = "TUIHSlider" .. sliderCount
    local s = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 28, y)
    s:SetWidth(220)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    _G[name .. "Low"]:SetText(min .. " s")
    _G[name .. "High"]:SetText(max .. " s")
    local text = _G[name .. "Text"]
    local refreshing = false
    local function show(v) text:SetText(string.format("%s: %.1f s", label, v)) end
    s:SetScript("OnValueChanged", function(_, v)
      v = tonumber(string.format("%.1f", v))
      show(v)
      if not refreshing then set(v) end
    end)
    refreshers[#refreshers + 1] = function()
      refreshing = true
      s:SetValue(get())
      show(get())
      refreshing = false
    end
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
  addNote(y - 62, ns.COMBAT_WARNING, true)

  addCheck(y - 100, "Enter mouselook while the UI is hidden (right-click style)",
    function() return TUIHDB.mouselookAuto end,
    function(v) ns.setMouselookAuto(v) end)
  addNote(y - 124, ns.MOUSELOOK_INFO)

  addCheck(y - 150, "Show the minimap icon",
    function() return TUIHDB.minimapIcon end,
    function(v) ns.setMinimapIcon(v) end)

  addCheck(y - 176, "Show True UI Hide events in chat (for debugging)",
    function() return TUIHDB.verbose end,
    function(v) TUIHDB.verbose = v end)

  addCheck(y - 202, "Show the red warning dot if hide settings stay on while the UI is visible",
    function() return TUIHDB.indicator end,
    function(v) TUIHDB.indicator = v; ns.updateIndicator() end)

  heading(y - 246, "Screenshot:")
  addCheck(y - 268, "Show the UI if combat starts during a screenshot",
    function() return TUIHDB.shotCombatShow end,
    function(v) TUIHDB.shotCombatShow = v end)
  addNote(y - 294, ns.SHOT_COMBAT_WARNING, true)
  addSlider(y - 348, "Wait before the screenshot", ns.SHOT_WAIT_MIN, ns.SHOT_WAIT_MAX, 0.1,
    function() return TUIHDB.shotBefore end,
    function(v) TUIHDB.shotBefore = v end)
  addSlider(y - 396, "Wait after the screenshot", ns.SHOT_WAIT_MIN, ns.SHOT_WAIT_MAX, 0.1,
    function() return TUIHDB.shotAfter end,
    function(v) TUIHDB.shotAfter = v end)
  addNote(y - 418, "The UI is hidden this long before the screenshot is taken, and stays hidden this long afterwards.")

  local py = y - 464
  heading(py, "Presets:")
  local function addButton(i, text, onClick)
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
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

  -- Maintenance: the two "start over" buttons, explained
  local rows = math.ceil(#ns.presetOrder / 3)
  local my = py - 24 - rows * 30 - 16
  heading(my, "If something is wrong:")
  local function addMaintButton(x, text, onClick)
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    b:SetSize(140, 24)
    b:SetPoint("TOPLEFT", x, my - 24)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
  end
  addMaintButton(20, "Reset", function()
    ns.reset()
    refreshAll()
  end)
  addMaintButton(170, "Delete all data", function()
    StaticPopup_Show("TUIH_WIPE")
  end)
  addNote(my - 56, "Reset: shows the UI, restores your game settings and clears the kept elements. Presets and your other options stay. Use it when the UI or names look wrong.", false, true)
  addNote(my - 92, "Delete all data: the nuclear option. Restores your game settings first, then deletes everything the addon saved (presets, options, icon position) and starts fresh. Use it when the addon itself misbehaves.", true, true)

  -- Make the scrollable area exactly as tall as its content
  content:SetHeight(-my + 92 + 48 + 24)

  -- Checkboxes always reflect the current settings when the panel opens
  cfg:SetScript("OnShow", refreshAll)
end

function ns.refreshOptions()
  refreshAll()
end

StaticPopupDialogs["TUIH_WIPE"] = {
  text = "Delete ALL True UI Hide data (presets, options) and start fresh?\nYour game settings are restored first. This cannot be undone.",
  button1 = "Delete everything",
  button2 = CANCEL,
  OnAccept = function() ns.wipeAll() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

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
