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

  -- Parent of everything the helpers below create. Switched to the "tail"
  -- frame for the sections that follow the (variable length) presets list.
  local host = content

  local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("|cffa335eeTrue UI Hide|r")

  local function heading(y, text)
    local fs = host:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 20, y)
    fs:SetText(text)
    return fs
  end

  local function addCheck(y, text, get, set)
    local cb = CreateFrame("CheckButton", nil, host, "UICheckButtonTemplate")
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
    local fs = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
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
    local s = CreateFrame("Slider", name, host, "OptionsSliderTemplate")
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

  local py = y - 14
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
      ns.applyPresetSettings(self.preset)
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
  local emptyNote = addNote(cy - 24, "None yet. Save the current state below.", false, true)

  -- Save the current state as a new custom preset
  local saveBox = CreateFrame("EditBox", "TUIHPresetName", content, "InputBoxTemplate")
  saveBox:SetSize(140, 20)
  saveBox:SetAutoFocus(false)
  saveBox:SetMaxLetters(24)
  local saveBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  saveBtn:SetSize(150, 24)
  saveBtn:SetText("Save current as preset")
  function ns.clearSaveBox()
    saveBox:SetText("")
    saveBox:ClearFocus()
  end
  local function savePreset()
    local name = (saveBox:GetText():match("^%s*(%S*)") or ""):lower()
    if TUIHDB.presets[name] then
      -- Saving over an existing preset asks first (the command does not)
      StaticPopup_Show("TUIH_OVERWRITE_PRESET", name, nil, name)
    elseif ns.savePreset(name) then
      ns.clearSaveBox()
    end
  end
  saveBtn:SetScript("OnClick", savePreset)
  saveBox:SetScript("OnEnterPressed", savePreset)
  saveBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  local saveNote = addNote(0, "Saves the kept elements and the player-name stage you have right now. Letters, digits, - and _ only.", false, true)

  -- Everything after the presets hangs on this frame; layout() moves it
  -- down as the custom list grows
  local tail = CreateFrame("Frame", nil, content)
  tail:SetSize(1, 1)
  host = tail
  y = 0

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

  addCheck(y - 228, "Show a chat message when cycling presets with the keybind",
    function() return TUIHDB.cycleMessage end,
    function(v) TUIHDB.cycleMessage = v end)

  heading(y - 272, "Screenshot:")
  addCheck(y - 294, "Show the UI if combat starts during a screenshot",
    function() return TUIHDB.shotCombatShow end,
    function(v) TUIHDB.shotCombatShow = v end)
  addNote(y - 320, ns.SHOT_COMBAT_WARNING, true)
  addSlider(y - 374, "Wait before the screenshot", ns.SHOT_WAIT_MIN, ns.SHOT_WAIT_MAX, 0.1,
    function() return TUIHDB.shotBefore end,
    function(v) TUIHDB.shotBefore = v end)
  addSlider(y - 422, "Wait after the screenshot", ns.SHOT_WAIT_MIN, ns.SHOT_WAIT_MAX, 0.1,
    function() return TUIHDB.shotAfter end,
    function(v) TUIHDB.shotAfter = v end)
  addNote(y - 444, "The UI is hidden this long before the screenshot is taken, and stays hidden this long afterwards.")

  local TAIL_MAINT = -480  -- below the Screenshot section
  local mHeading = heading(0, "If something is wrong:")
  local function addMaintButton(x, text, onClick)
    local b = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
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
  local namesBtn = addMaintButton(320, "Reset name settings", function()
    StaticPopup_Show("TUIH_NAMES_RESET")
  end)
  namesBtn:SetWidth(180)
  local namesNote = addNote(0, "Reset name settings: puts all name tag and nameplate settings back to the game's defaults (your current values for them are lost). Use it when names or nameplates look wrong.", false, true)
  local resetNote = addNote(0, "Reset: shows the UI, restores your game settings and clears the kept elements. Presets and your other options stay. Use it when the UI or names look wrong.", false, true)
  local wipeNote = addNote(0, "Delete all data: the nuclear option. Restores your game settings first, then deletes everything the addon saved (presets, options, icon position) and starts fresh. Use it when the addon itself misbehaves.", true, true)

  -- Advanced: the client's on/off soft-target settings, collapsed by default
  local SOFT_Y = TAIL_MAINT - 190
  local softExpanded, softBuilt, softRows, baseTy = false, false, 0, 0
  local softChecks = {}
  local function setHeight()
    content:SetHeight(-baseTy - TAIL_MAINT + 190 + 40 + (softExpanded and (softRows * 28 + 30) or 0) + 24)
  end
  local softBtn = CreateFrame("Button", nil, tail, "UIPanelButtonTemplate")
  softBtn:SetSize(280, 24)
  softBtn:SetPoint("TOPLEFT", 20, SOFT_Y)
  softBtn:SetText("Show soft-target settings (advanced)")
  local softReset = CreateFrame("Button", nil, tail, "UIPanelButtonTemplate")
  softReset:SetSize(190, 24)
  softReset:SetPoint("TOPLEFT", 310, SOFT_Y)
  softReset:SetText("Reset all to game defaults")
  softReset:SetScript("OnClick", function() StaticPopup_Show("TUIH_SOFT_RESET") end)
  softReset:Hide()
  local softNote = addNote(SOFT_Y - 28, "These are game settings, not addon settings. A change applies immediately and is saved by the game.", false, true)
  softNote:Hide()

  -- Settings with plain 0/1 values only; ranges, sizes and so on are skipped
  local numericName = { "Range$", "Arc$", "Size$", "Dist$", "Scale$", "DurationMs$", "Tutorial" }
  local function isOnOff(name)
    if not name:find("OnlyInRange$") then
      for _, p in ipairs(numericName) do
        if name:find(p) then return false end
      end
    end
    local cur = GetCVar(name)
    local def = GetCVarDefault and GetCVarDefault(name)
    return (cur == "0" or cur == "1") and (def == nil or def == "0" or def == "1")
  end
  local function refreshSoft()
    for _, e in ipairs(softChecks) do
      e.cb:SetChecked(GetCVar(e.name) == "1")
      e.cb:SetShown(softExpanded)
    end
    softNote:SetShown(softExpanded)
    softReset:SetShown(softExpanded)
  end
  local function buildSoft()
    if softBuilt then return end
    softBuilt = true
    local names = {}
    for _, info in ipairs(ns.getAllCommands() or {}) do
      local n = info.command or info.name
      if n and ns.isSoftTarget(n) and isOnOff(n) then names[#names + 1] = n end
    end
    table.sort(names)
    softRows = math.ceil(#names / 2)
    for i, n in ipairs(names) do
      local cb = CreateFrame("CheckButton", nil, tail, "UICheckButtonTemplate")
      cb:SetSize(24, 24)
      cb:SetPoint("TOPLEFT", 20 + ((i - 1) % 2) * 270, SOFT_Y - 52 - math.floor((i - 1) / 2) * 28)
      local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      fs:SetPoint("LEFT", cb, "RIGHT", 4, 1)
      fs:SetText(n)
      cb:SetScript("OnClick", function(self)
        pcall(SetCVar, n, self:GetChecked() and "1" or "0")
        self:SetChecked(GetCVar(n) == "1")  -- shows the real result
      end)
      softChecks[#softChecks + 1] = { cb = cb, name = n }
    end
  end
  softBtn:SetScript("OnClick", function()
    softExpanded = not softExpanded
    if softExpanded then buildSoft() end
    softBtn:SetText(softExpanded and "Hide soft-target settings" or "Show soft-target settings (advanced)")
    refreshSoft()
    setHeight()
  end)
  refreshers[#refreshers + 1] = refreshSoft

  -- Places the save row, the tail sections and the scroll height
  local function layout(customCount)
    local rows = math.ceil(customCount / 3)
    local sy = cy - 24 - (customCount == 0 and 24 or rows * 30) - 4
    saveBox:ClearAllPoints()
    saveBox:SetPoint("TOPLEFT", 30, sy - 2)
    saveBtn:ClearAllPoints()
    saveBtn:SetPoint("TOPLEFT", 180, sy)
    saveNote:ClearAllPoints()
    saveNote:SetPoint("TOPLEFT", 44, sy - 30)
    local ty = sy - 30 - 28 - 16
    tail:ClearAllPoints()
    tail:SetPoint("TOPLEFT", content, "TOPLEFT", 0, ty)
    local my = TAIL_MAINT
    mHeading:ClearAllPoints()
    mHeading:SetPoint("TOPLEFT", 20, my)
    resetBtn:ClearAllPoints()
    resetBtn:SetPoint("TOPLEFT", 20, my - 24)
    wipeBtn:ClearAllPoints()
    wipeBtn:SetPoint("TOPLEFT", 170, my - 24)
    namesBtn:ClearAllPoints()
    namesBtn:SetPoint("TOPLEFT", 320, my - 24)
    resetNote:ClearAllPoints()
    resetNote:SetPoint("TOPLEFT", 44, my - 56)
    namesNote:ClearAllPoints()
    namesNote:SetPoint("TOPLEFT", 44, my - 92)
    wipeNote:ClearAllPoints()
    wipeNote:SetPoint("TOPLEFT", 44, my - 128)
    baseTy = ty
    setHeight()
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
      b:SetWidth(98)  -- room for the delete button
      b:SetText(capitalize(name))
      b:ClearAllPoints()
      local bx, by = 20 + ((i - 1) % 3) * 130, cy - 24 - math.floor((i - 1) / 3) * 30
      b:SetPoint("TOPLEFT", bx, by)
      b:Show()
      local d = b.delete
      if not d then
        d = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        d:SetSize(22, 24)
        d:SetText("x")
        d:SetScript("OnClick", function(self)
          StaticPopup_Show("TUIH_DELETE_PRESET", self.preset, nil, self.preset)
        end)
        d:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:AddLine("Delete preset " .. self.preset)
          GameTooltip:Show()
        end)
        d:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b.delete = d
      end
      d.preset = name
      d:ClearAllPoints()
      d:SetPoint("TOPLEFT", bx + 100, by)
      d:Show()
    end
    for i = #names + 1, #customButtons do
      customButtons[i]:Hide()
      if customButtons[i].delete then customButtons[i].delete:Hide() end
    end
    emptyNote:SetShown(#names == 0)
    layout(#names)
  end

  -- Checkboxes always reflect the current settings when the panel opens
  cfg:SetScript("OnShow", refreshAll)
end

function ns.refreshOptions()
  refreshAll()
end

StaticPopupDialogs["TUIH_NAMES_RESET"] = {
  text = "Reset ALL name tag and nameplate settings to the game's default values?\nYour current values for them are lost.",
  button1 = "Reset",
  button2 = CANCEL,
  OnAccept = function()
    ns.resetNameSettings()
    ns.refreshOptions()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["TUIH_SOFT_RESET"] = {
  text = "Reset ALL soft-target settings to the game's default values?\nYour current values for them are lost.",
  button1 = "Reset",
  button2 = CANCEL,
  OnAccept = function()
    ns.resetSoftTargets()
    ns.refreshOptions()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["TUIH_OVERWRITE_PRESET"] = {
  text = "The custom preset \"%s\" already exists. Overwrite it with the current state?",
  button1 = "Overwrite",
  button2 = CANCEL,
  OnAccept = function(_, name)
    if ns.savePreset(name) and ns.clearSaveBox then ns.clearSaveBox() end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["TUIH_DELETE_PRESET"] = {
  text = "Delete the custom preset \"%s\"?",
  button1 = DELETE or "Delete",
  button2 = CANCEL,
  OnAccept = function(_, name) ns.deletePreset(name) end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

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
