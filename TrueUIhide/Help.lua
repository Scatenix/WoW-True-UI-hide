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
      { "/tuih players  (p)", "cycle own / friendly player names" },
      { "/tuih enemies  (e)", "cycle enemy player / hostile mob names" },
      { "/tuih shot  (ss)", "screenshot without UI" },
      { "/tuih mouselook  (look, ml)", "enter or leave mouselook (right-click style)" },
      { "/tuih status  (s)", "show current settings" },
      { "/tuih config  (cfg, o)", "open the options panel" },
      { "/tuih menu  (gamemenu)", "open or close the game menu (also while hidden)" },
      { "/tuih reset", "back to normal, clear saved state" },
      { "/tuih wipe", "delete all addon data and start fresh (asks first)" },
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
    key = "frames", label = "Own windows",
    title = "Keep any window visible by its frame name",
    rows = {
      { "/tuih keepframe pick  (kf)", "point at a window within 3 s: it is added" },
      { "/tuih keepframe add <name>", "add a frame by name (case-sensitive)" },
      { "/tuih keepframe remove <name>", "remove it from your list" },
      { "/tuih keepframe toggle <name>", "keep it or not (saved per preset)" },
      { "/tuih keepframe", "list your windows" },
      { "Keybind", "\"Keep the window under the mouse visible\": hover, press" },
      { "Settings", "\"Your own windows\": checkbox per window, Pick button" },
    },
  },
  {
    key = "presets", label = "Presets",
    rows = {
      { "Built-in", "PRESETLIST" },
      { "/tuih preset <name>", "apply a built-in or custom preset" },
      { "/tuih preset next  (cycle)", "apply the next preset (built-in and custom)" },
      { "/tuih preset next builtin", "apply the next built-in preset" },
      { "/tuih preset next custom", "apply the next custom preset" },
      { "/tuih preset prev  (previous)", "same, backwards (also: prev builtin, prev custom)" },
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
      { "/tuih set whisper", "show the chat for a while on a whisper while hidden" },
      { "/tuih set messages  (toast)", "on-screen messages when toggling or cycling" },
      { "/tuih set dot  (indicator)", "show or hide the red warning dot" },
      { "/tuih set verbose  (chat)", "show True UI Hide events in chat (for debugging)" },
    },
  },
}

-- One row per keepable element, built from the same list the addon uses
do
  local rows = ns.helpGroups[2].rows
  rows[1] = { "/tuih toggle <element>  (keep, k)", "keep it visible, or not" }
  rows[2] = { "/tuih toggle all", "keep everything, or nothing if all are kept" }
  for _, e in ipairs(ns.keepList) do
    local aliases = (e.alias and #e.alias > 0) and ("  (" .. table.concat(e.alias, ", ") .. ")") or ""
    rows[#rows + 1] = {
      e.key .. aliases,
      e.label:lower() .. (e.requires and (" (if " .. e.requires .. " is installed)") or ""),
    }
  end
end

-- The built-in preset names come from the data, so this list cannot go stale
for _, g in ipairs(ns.helpGroups) do
  if g.key == "presets" then g.rows[1][2] = table.concat(ns.presetOrder, ", ") end
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
  GameTooltip:AddDoubleLine("/tuih config", "open the settings", 1, 0.82, 0, 0.8, 0.8, 0.8)
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
