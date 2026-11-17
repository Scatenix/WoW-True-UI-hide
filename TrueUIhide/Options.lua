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
  local clearBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  clearBtn:SetSize(120, 22)
  clearBtn:SetPoint("TOPLEFT", 420, -48)
  clearBtn:SetText("Toggle all")
  clearBtn:SetScript("OnClick", function()
    ns.toggleKeepAll()
    refreshAll()
  end)
  clearBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Keeps every element below (and your own windows), or none of them if all are kept already. Does not change the UI.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  clearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  addNote(-70, "Keeping an element only leaves it as it is: if it is already turned off in the game, True UI Hide does not turn it on. Everything you do not keep is hidden or turned off while the UI is hidden.")
  -- Section title with a thin line below it
  local function groupHeader(y, text)
    local fs = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", 20, y)
    fs:SetText(text)
    fs:SetTextColor(0.64, 0.21, 0.93)
    local line = host:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.15)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", host, "TOPLEFT", 20, y - 14)
    line:SetPoint("TOPRIGHT", host, "TOPLEFT", 540, y - 14)
  end

  -- Keep elements: grouped, two per row; hover for a short description
  local COL_X = { 16, 286 }
  local function addKeepCheck(x, y, e)
    local cb = CreateFrame("CheckButton", nil, host, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetSize(24, 24)
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    fs:SetWidth(225)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs:SetText(e.label)
    cb:SetScript("OnClick", function(self) ns.setKeep(e.key, self:GetChecked() and true or false) end)
    if e.tip then
      cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(e.label, 1, 1, 1)
        GameTooltip:AddLine(e.tip, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
      end)
      cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    refreshers[#refreshers + 1] = function() cb:SetChecked(TUIHDB.keep[e.key]) end
  end

  local y = -112
  for _, g in ipairs(ns.keepGroups) do
    local items = {}
    for _, e in ipairs(ns.keepList) do
      if e.group == g.key and ns.available(e) then items[#items + 1] = e end
    end
    if #items > 0 then
      groupHeader(y, g.label)
      y = y - 22
      for i, e in ipairs(items) do
        addKeepCheck(COL_X[(i - 1) % 2 + 1], y - math.floor((i - 1) / 2) * 26, e)
      end
      y = y - math.ceil(#items / 2) * 26 - 10
    end
  end

  -- Your own frames: windows the player added by name. The list changes
  -- while the game runs, so everything below it hangs on `mid`, which is
  -- moved by the refresher further down.
  local cfY = y
  local midY = cfY - 22 - 26 - 6 - 30 - 42
  groupHeader(cfY, "Your own windows")
  local cfEmpty = addNote(cfY - 22, "None yet. Add a window by its frame name, or point at it and use Pick.", false, true)
  local cfRows = {}
  local cfBox = CreateFrame("EditBox", "TUIHFrameName", host, "InputBoxTemplate")
  cfBox:SetSize(150, 20)
  cfBox:SetAutoFocus(false)
  cfBox:SetMaxLetters(64)
  local cfAdd = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
  cfAdd:SetSize(60, 24)
  cfAdd:SetText("Add")
  local cfPick = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
  cfPick:SetSize(190, 24)
  cfPick:SetText("Pick the window under the mouse")
  local cfNote = addNote(0, "Pick closes this window and waits 3 seconds: point at the window you want to keep. Same as the keybind or /tuih keepframe pick. Frame names are case-sensitive.", false, true)
  local function addFrameFromBox()
    if ns.addCustomFrame(cfBox:GetText()) then
      cfBox:SetText("")
      cfBox:ClearFocus()
    end
  end
  cfAdd:SetScript("OnClick", addFrameFromBox)
  cfBox:SetScript("OnEnterPressed", addFrameFromBox)
  cfBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  cfPick:SetScript("OnClick", function()
    if SettingsPanel and SettingsPanel:IsShown() then
      HideUIPanel(SettingsPanel)
    elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
      InterfaceOptionsFrame:Hide()
    end
    ns.pickFrameLater(3)
  end)
  local function cfRow(i)
    local r = cfRows[i]
    if r then return r end
    r = {}
    r.cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    r.cb:SetSize(24, 24)
    r.cb:SetScript("OnClick", function(self)
      ns.setCustomKeep(self.frameName, self:GetChecked() and true or false)
    end)
    r.cb:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(self.frameName, 1, 1, 1)
      GameTooltip:AddLine("Keep this window visible (saved per preset)", 0.8, 0.8, 0.8, true)
      GameTooltip:Show()
    end)
    r.cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r.text = r.cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.text:SetPoint("LEFT", r.cb, "RIGHT", 4, 1)
    r.text:SetWidth(180)
    r.text:SetJustifyH("LEFT")
    r.text:SetWordWrap(false)
    r.del = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    r.del:SetSize(22, 22)
    r.del:SetText("x")
    r.del:SetScript("OnClick", function(self) ns.removeCustomFrame(self.frameName) end)
    r.del:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine("Remove " .. self.frameName .. " from the list")
      GameTooltip:Show()
    end)
    r.del:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cfRows[i] = r
    return r
  end
  refreshers[#refreshers + 1] = function()
    local list = ns.customFrameList()
    for i, name in ipairs(list) do
      local r = cfRow(i)
      local x = 16 + ((i - 1) % 2) * 270
      local ry = cfY - 22 - math.floor((i - 1) / 2) * 26
      r.cb:ClearAllPoints()
      r.cb:SetPoint("TOPLEFT", x, ry)
      r.cb.frameName = name
      r.cb:SetChecked(ns.customKept(name))
      r.cb:Show()
      r.text:SetText(name)
      r.del:ClearAllPoints()
      r.del:SetPoint("TOPLEFT", x + 214, ry - 1)
      r.del.frameName = name
      r.del:Show()
    end
    for i = #list + 1, #cfRows do
      cfRows[i].cb:Hide()
      cfRows[i].del:Hide()
    end
    cfEmpty:SetShown(#list == 0)
    local rows = math.max(1, math.ceil(#list / 2))
    local iy = cfY - 22 - rows * 26 - 6
    cfBox:ClearAllPoints()
    cfBox:SetPoint("TOPLEFT", 30, iy - 2)
    cfAdd:ClearAllPoints()
    cfAdd:SetPoint("TOPLEFT", 188, iy)
    cfPick:ClearAllPoints()
    cfPick:SetPoint("TOPLEFT", 256, iy)
    cfNote:ClearAllPoints()
    cfNote:SetPoint("TOPLEFT", 44, iy - 30)
    midY = iy - 30 - 42
    if ns.moveMid then ns.moveMid(midY) end
  end

  local mid = CreateFrame("Frame", nil, content)
  mid:SetSize(1, 1)
  mid:SetPoint("TOPLEFT", content, "TOPLEFT", 0, midY)
  function ns.moveMid(v)
    mid:ClearAllPoints()
    mid:SetPoint("TOPLEFT", content, "TOPLEFT", 0, v)
  end
  host = mid
  y = 0

  -- Player names while the UI is hidden (a dropdown, like the game's own menu)
  local nameChoices = { [0] = "No player names", "Own name only", "Other players only", "Own and other players" }
  groupHeader(y, "Player names")
  local nameLabel = host:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  nameLabel:SetPoint("TOPLEFT", 20, y - 26)
  nameLabel:SetText("Show these player names while the UI is hidden:")
  local nameDD = CreateFrame("Frame", "TUIHPlayerNamesDropDown", host, "UIDropDownMenuTemplate")
  nameDD:SetPoint("TOPLEFT", 4, y - 42)
  UIDropDownMenu_SetWidth(nameDD, 200)
  UIDropDownMenu_Initialize(nameDD, function()
    for i = 0, 3 do
      local info = UIDropDownMenu_CreateInfo()
      info.text = nameChoices[i]
      info.checked = (TUIHDB.playerNames or 0) == i
      info.func = function()
        ns.setPlayerNames(i)
        UIDropDownMenu_SetText(nameDD, nameChoices[i])
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  refreshers[#refreshers + 1] = function()
    UIDropDownMenu_SetText(nameDD, nameChoices[TUIHDB.playerNames or 0])
  end
  addNote(y - 76, "This is the exception to the list above: the names you choose here are actually turned on while the UI is hidden, even if they were off in the game.", false, true)
  y = y - 114

  local py = y - 14
  heading(py, "Built-in presets:")
  local function capitalize(name)
    return name:sub(1, 1):upper() .. name:sub(2)
  end
  -- Labels of what a preset keeps, for its tooltip
  local function keptText(name)
    local p = ns.builtin[name] or TUIHDB.presets[name]
    if not p or not p.keep then return nil end
    local labels = {}
    for k in pairs(p.keep) do
      local e = ns.keepByKey[k]
      labels[#labels + 1] = e and e.label or (k:match("^frame:(.+)") or k)
    end
    table.sort(labels)
    return #labels > 0 and table.concat(labels, ", ") or "nothing"
  end
  local function presetButton(x, by, name)
    local b = CreateFrame("Button", nil, mid, "UIPanelButtonTemplate")
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
      GameTooltip:AddLine(self.preset, 1, 1, 1)
      local kept = keptText(self.preset)
      if kept then GameTooltip:AddLine("Keeps: " .. kept, 0.8, 0.8, 0.8, true) end
      GameTooltip:AddLine("Only changes the settings. Use the keybind or /tuih preset to apply it.", 0.6, 0.6, 0.6, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
  end
  local panelPresets = {}
  for _, name in ipairs(ns.presetOrder) do panelPresets[#panelPresets + 1] = name end
  for i, name in ipairs(panelPresets) do
    presetButton(20 + ((i - 1) % 3) * 130, py - 24 - math.floor((i - 1) / 3) * 30, name)
  end

  -- Custom presets: the list changes while the game runs, so everything
  -- below it is placed by layout() and the buttons are reused
  local cy = py - 24 - math.ceil(#panelPresets / 3) * 30 - 16
  heading(cy, "Custom presets:")
  local emptyNote = addNote(cy - 24, "None yet. Save the current state below.", false, true)

  -- Save the current state as a new custom preset
  local saveBox = CreateFrame("EditBox", "TUIHPresetName", mid, "InputBoxTemplate")
  saveBox:SetSize(140, 20)
  saveBox:SetAutoFocus(false)
  saveBox:SetMaxLetters(24)
  local saveBtn = CreateFrame("Button", nil, mid, "UIPanelButtonTemplate")
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

  -- Limits: only a safety net against runaway lists
  heading(y - 484, "Limits:")
  local limitLabel = host:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  limitLabel:SetPoint("TOPLEFT", 44, y - 510)
  limitLabel:SetText("Max windows in \"Your own windows\":")
  local limitBox = CreateFrame("EditBox", "TUIHCustomLimit", host, "InputBoxTemplate")
  limitBox:SetSize(60, 20)
  limitBox:SetPoint("TOPLEFT", 280, y - 508)
  limitBox:SetAutoFocus(false)
  limitBox:SetNumeric(true)
  limitBox:SetMaxLetters(5)
  local function applyLimit(self)
    local n = math.floor(tonumber(self:GetText()) or 0)
    if n < 1 then n = ns.customLimit() end
    if n > 10000 then n = 10000 end
    TUIHDB.customLimit = (n ~= ns.DEFAULT_CUSTOM_LIMIT) and n or nil
    self:SetText(tostring(ns.customLimit()))
    self:ClearFocus()
  end
  limitBox:SetScript("OnEnterPressed", applyLimit)
  limitBox:SetScript("OnEditFocusLost", applyLimit)
  limitBox:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(ns.customLimit()))
    self:ClearFocus()
  end)
  refreshers[#refreshers + 1] = function() limitBox:SetText(tostring(ns.customLimit())) end
  addNote(y - 536, "This is just a small limit so the list cannot grow by accident. Raise it if you really need more windows (default " .. ns.DEFAULT_CUSTOM_LIMIT .. ").", false, true)

  local TAIL_MAINT = -590  -- below the Limits section
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
    tail:SetPoint("TOPLEFT", mid, "TOPLEFT", 0, ty)
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
    baseTy = midY + ty
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
        d = CreateFrame("Button", nil, mid, "UIPanelButtonTemplate")
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
