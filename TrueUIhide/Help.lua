-- Help: hoverable chat links and tooltips.
-- The [TUIH] tag on every message shows a short general tooltip. /tuih help
-- prints one link per topic; each topic has its own (short) tooltip, so no
-- tooltip can grow bigger than the screen.
local _, ns = ...

-- Topics, in display order. Each row is { command, description }.
ns.helpGroups = {
  {
    key = "main", label = "Main",
    rows = {
      { "/tuih", "toggle all UI" },
      { "/tuih on | off", "show or hide all UI" },
      { "/tuih players  (p)", "cycle player names (and hide player plates)" },
      { "/tuih shot  (ss)", "screenshot without UI" },
      { "/tuih mouselook  (look, ml)", "enter or leave mouselook (right-click style)" },
      { "/tuih status  (s)", "show current settings" },
      { "/tuih config  (cfg, o)", "open the options panel" },
      { "/tuih reset", "back to normal, clear saved state" },
      { "/tuih help  (h, ?)", "show the help links" },
      { "/tuih diff  (d)", "find the CVar of a menu option" },
    },
  },
  {
    key = "elements", label = "Elements",
    title = "Elements kept visible while the UI is hidden",
    rows = {},  -- filled below from the element list
  },
  {
    key = "presets", label = "Presets",
    rows = {
      { "/tuih preset <name>", "apply a built-in or custom preset" },
      { "/tuih preset list", "list all presets" },
      { "/tuih preset save <name>", "save the current state as a preset" },
      { "/tuih preset delete <name>", "delete one of your presets" },
    },
  },
  {
    key = "settings", label = "Settings",
    rows = {
      { "/tuih set combat", "show the UI during combat (may be blocked by the game)" },
      { "/tuih set mouselook", "enter mouselook whenever the UI is hidden" },
      { "/tuih set icon", "show or hide the minimap icon" },
      { "/tuih set shotcombat", "show the UI if combat starts during a screenshot" },
    },
  },
}

-- One row per keepable element, built from the same list the addon uses
do
  local rows = ns.helpGroups[2].rows
  rows[1] = { "/tuih toggle <element>  (keep, k)", "keep it visible, or not" }
  for _, e in ipairs(ns.keepList) do
    local aliases = (e.alias and #e.alias > 0) and ("  (" .. table.concat(e.alias, ", ") .. ")") or ""
    rows[#rows + 1] = {
      e.key .. aliases,
      e.label:lower() .. (e.requires and (" (if " .. e.requires .. " is installed)") or ""),
    }
  end
end

local groupByLinkKey = {}
for _, g in ipairs(ns.helpGroups) do groupByLinkKey["help_" .. g.key] = g end

-- Prints one hoverable link per topic
function ns.showHelp()
  local parts = {}
  for _, g in ipairs(ns.helpGroups) do
    parts[#parts + 1] = ns.link(g.label, "help_" .. g.key)
  end
  ns.log("Hover for commands: " .. table.concat(parts, " "), "help")
end

local function showGroup(g)
  GameTooltip:AddLine(g.title or g.label, 0.64, 0.21, 0.93)
  GameTooltip:AddLine(" ")
  for _, r in ipairs(g.rows) do
    GameTooltip:AddDoubleLine(r[1], r[2], 1, 0.82, 0, 0.8, 0.8, 0.8)
  end
end

local function showGeneral()
  GameTooltip:AddLine("True UI Hide", 0.64, 0.21, 0.93)
  GameTooltip:AddLine("Toggle truly all UI!", 1, 1, 1)
  GameTooltip:AddLine(" ")
  GameTooltip:AddDoubleLine("/tuih", "toggle all UI", 1, 0.82, 0, 0.8, 0.8, 0.8)
  GameTooltip:AddDoubleLine("/tuih on | off", "show or hide all UI", 1, 0.82, 0, 0.8, 0.8, 0.8)
  GameTooltip:AddDoubleLine("/tuih help", "show more available commands", 1, 0.82, 0, 0.8, 0.8, 0.8)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Keybinds for TUIH are available", 1, 1, 1)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Thanks for using True UI Hide!", 1, 0.82, 0)
end

local function onEnter(frame, link)
  local kind, addon, key = strsplit(":", link)
  if kind ~= "addon" or addon ~= "TUIH" then return end
  GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
  local g = groupByLinkKey[key]
  if g then showGroup(g) else showGeneral() end
  GameTooltip:Show()
end

local hooked = {}
local function hookChatFrame(f)
  if not f or hooked[f] or not f.HookScript then return end
  hooked[f] = true
  f:HookScript("OnHyperlinkEnter", onEnter)
  f:HookScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
end

for i = 1, NUM_CHAT_WINDOWS or 10 do
  hookChatFrame(_G["ChatFrame" .. i])
end

-- Pop-out and temporary windows (whisper tabs, ...) are created later
if FCF_OpenTemporaryWindow then
  hooksecurefunc("FCF_OpenTemporaryWindow", function()
    for i = 1, 50 do
      local f = _G["ChatFrame" .. i]
      if not f then break end
      hookChatFrame(f)
    end
  end)
end
