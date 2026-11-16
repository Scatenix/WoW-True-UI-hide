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
    return fs
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
    return fs
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
  heading(py, "Built-in presets:")
  local function capitalize(name)
    return name:sub(1, 1):upper() .. name:sub(2)
  end
  local function presetButton(x, by, name)
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    b:SetSize(120, 24)
    b:SetPoint("TOPLEFT", x, by)
    b:SetText(capitalize(name))
    b.preset = name  -- custom buttons are reused for other presets later
    b:SetScript("OnClick", function(self)
      ns.applyPreset(self.preset)
      refreshAll()
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(self.preset)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
  end
  for i, name in ipairs(ns.presetOrder) do
    presetButton(20 + ((i - 1) % 3) * 130, py - 24 - math.floor((i - 1) / 3) * 30, name)
  end

  -- Custom presets: the list changes while the game runs, so everything
  -- below it is placed by layout() and the buttons are reused
  local cy = py - 24 - math.ceil(#ns.presetOrder / 3) * 30 - 16
  heading(cy, "Custom presets:")
  local emptyNote = addNote(cy - 24, "None yet. Save the current state with /tuih preset save <name>.", false, true)

  local mHeading = heading(0, "If something is wrong:")
  local function addMaintButton(x, text, onClick)
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    b:SetSize(140, 24)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
  end
  local resetBtn = addMaintButton(20, "Reset", function()
    ns.reset()
    refreshAll()
  end)
  local wipeBtn = addMaintButton(170, "Delete all data", function()
    StaticPopup_Show("TUIH_WIPE")
  end)
  local resetNote = addNote(0, "Reset: shows the UI, restores your game settings and clears the kept elements. Presets and your other options stay. Use it when the UI or names look wrong.", false, true)
  local wipeNote = addNote(0, "Delete all data: the nuclear option. Restores your game settings first, then deletes everything the addon saved (presets, options, icon position) and starts fresh. Use it when the addon itself misbehaves.", true, true)

  -- Places the section below the custom presets and sizes the scroll area
  local function layout(customCount)
    local rows = math.ceil(customCount / 3)
    local my = cy - 24 - (customCount == 0 and 24 or rows * 30) - 16
    mHeading:ClearAllPoints()
    mHeading:SetPoint("TOPLEFT", 20, my)
    resetBtn:ClearAllPoints()
    resetBtn:SetPoint("TOPLEFT", 20, my - 24)
    wipeBtn:ClearAllPoints()
    wipeBtn:SetPoint("TOPLEFT", 170, my - 24)
    resetNote:ClearAllPoints()
    resetNote:SetPoint("TOPLEFT", 44, my - 56)
    wipeNote:ClearAllPoints()
    wipeNote:SetPoint("TOPLEFT", 44, my - 92)
    content:SetHeight(-my + 92 + 48 + 24)
  end

  local customButtons = {}
  refreshers[#refreshers + 1] = function()
    local names = {}
    for name, p in pairs(TUIHDB.presets) do
      if type(name) == "string" and type(p) == "table" then names[#names + 1] = name end
    end
    table.sort(names)
    for i, name in ipairs(names) do
      local b = customButtons[i]
      if not b then
        b = presetButton(0, 0, name)
        customButtons[i] = b
      end
      b.preset = name
      b:SetText(capitalize(name))
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", 20 + ((i - 1) % 3) * 130, cy - 24 - math.floor((i - 1) / 3) * 30)
      b:Show()
    end
    for i = #names + 1, #customButtons do customButtons[i]:Hide() end
    emptyNote:SetShown(#names == 0)
    layout(#names)
  end

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
