-- Help: hoverable help link and tooltip
local _, ns = ...

ns.help = {
  { "/tuih", "toggle all UI" },
  { "/tuih on | off", "show or hide all UI" },
  { "/tuih p  (/tuihp)", "cycle player names (and hide player plates)" },
  { "/tuih minimap  (map, m)", "keep the minimap while hidden" },
  { "/tuih player  (pf)", "keep the player frame" },
  { "/tuih target  (tf, t)", "keep the target frame" },
  { "/tuih plates  (np, ep)", "keep enemy nameplates" },
  { "/tuih chat  (c)", "keep the chat" },
  { "/tuih bars  (ab)", "keep the action bars" },
  { "/tuih buffs  (b)", "keep buffs and debuffs" },
  { "/tuih quest  (q)", "keep the quest tracker" },
  { "/tuih questie  (qt)", "keep the Questie tracker (if installed)" },
  { "/tuih cast  (cb)", "keep the cast bar" },
  { "/tuih combat", "show the UI during combat (may be blocked by the game)" },
  { "/tuih config  (cfg, o)", "open the options panel" },
  { "/tuih normal | explore | social", "apply a preset" },
  { "/tuih immersive | screenshot", "apply a preset" },
  { "/tuih preset save | delete | list", "manage your own presets" },
  { "/tuih shot  (ss)", "screenshot without UI" },
  { "/tuih status  (s)", "show current settings" },
  { "/tuih reset", "back to normal, clear saved state" },
  { "/tuih diff  (d)", "find the CVar of a menu option" },
  { "/tuih help  (h, ?)", "show this help link" },
}

function ns.showHelp()
  print(ns.link("TUIH  -  hover here for help", "help"))
end

local function onEnter(frame, link)
  local kind, addon, key = strsplit(":", link)
  if kind ~= "addon" or addon ~= "TUIH" then return end
  GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
  GameTooltip:AddLine("True UI hide", 0.64, 0.21, 0.93)
  if key == "status" or key == "help" then
    GameTooltip:AddLine("Toggle truly all UI!", 1, 1, 1)
  end
  GameTooltip:AddLine(" ")
  for _, h in ipairs(ns.help) do
    GameTooltip:AddDoubleLine(h[1], h[2], 1, 0.82, 0, 0.8, 0.8, 0.8)
  end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Keybinds for TUIH are available", 1, 1, 1)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Thanks for using True UI hide!", 1, 0.82, 0)
  GameTooltip:Show()
end

for i = 1, NUM_CHAT_WINDOWS do
  local f = _G["ChatFrame" .. i]
  if f then
    f:HookScript("OnHyperlinkEnter", onEnter)
    f:HookScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
  end
end