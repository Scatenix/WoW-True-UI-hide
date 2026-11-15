-- Data: static lists (CVars, keepable elements, presets)
local _, ns = ...

-- Known CVars; more are discovered by prefix
ns.baseCVars = {
  "UnitNameOwn","UnitNameNPC","UnitNameInteractiveNPC","UnitNameHostleNPC",
  "UnitNameFriendlyPlayerName","UnitNameEnemyPlayerName",
  "UnitNameFriendlyPetName","UnitNameEnemyPetName",
  "UnitNameFriendlyGuardianName","UnitNameEnemyGuardianName",
  "UnitNameFriendlyMinionName","UnitNameEnemyMinionName",
  "UnitNameFriendlySpecialNPCName",
  "UnitNameFriendlyTotemName","UnitNameEnemyTotemName",
  "UnitNameNonCombatCreatureName","UnitNameGuildTitle",
  "UnitNamePlayerGuild","UnitNamePlayerPVPTitle",
  "nameplateShowAll","nameplateShowEnemies","nameplateShowFriends",
  "nameplateShowFriendlyNPCs",
}
ns.prefixes = { "unitname", "nameplateshow", "softtarget" }

local function chatNames()
  local n = { "GeneralDockManager", "GENERAL_CHAT_DOCK" }
  for i = 1, NUM_CHAT_WINDOWS or 10 do
    n[#n + 1] = "ChatFrame" .. i
    n[#n + 1] = "ChatFrame" .. i .. "Tab"
    n[#n + 1] = "ChatFrame" .. i .. "EditBox"
  end
  return n
end

-- Action bar containers: found through their first button, so the
-- frame names do not have to be known
local function actionBarFrames()
  local out = {
    "MainMenuBar", "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
    "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
    "StanceBarFrame", "StanceBar", "PetActionBarFrame", "PetActionBar",
    "MultiCastActionBarFrame",
  }
  local buttonPrefixes = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
    "MultiBar6Button", "MultiBar7Button", "PetActionButton", "StanceButton",
  }
  for _, p in ipairs(buttonPrefixes) do
    local b = _G[p .. "1"]
    local par = b and b.GetParent and b:GetParent()
    if par and par ~= UIParent and par ~= WorldFrame then
      out[#out + 1] = par
    end
  end
  return out
end

-- Elements that can stay visible while the UI is hidden.
-- Entries without "frames" are handled through CVars.
-- Entries with "requires" only work when that global exists (other addons).
-- "frames" can be a list of names or a function that returns names/frames.
ns.keepList = {
  { key = "minimap", label = "Minimap",
    alias = { "map", "m" },
    frames = { "MinimapCluster" } },
  { key = "player", label = "Player frame",
    alias = { "pf" },
    frames = { "PlayerFrame" } },
  { key = "target", label = "Target frame",
    alias = { "tf", "t" },
    frames = { "TargetFrame" } },
  { key = "enemyplates", label = "Enemy nameplates",
    alias = { "plates", "nameplates", "np", "ep" } },
  { key = "chat", label = "Chat",
    alias = { "c" },
    frames = chatNames },
  { key = "actionbars", label = "Action bars",
    alias = { "bars", "ab", "actionbar" },
    frames = actionBarFrames },
  { key = "buffs", label = "Buffs and debuffs",
    alias = { "b", "auras" },
    frames = { "BuffFrame", "TemporaryEnchantFrame" } },
  { key = "quest", label = "Quest tracker",
    alias = { "q", "tracker" },
    frames = { "QuestWatchFrame", "ObjectiveTrackerFrame", "WatchFrame" } },
  { key = "questie", label = "Questie tracker",
    alias = { "qt" },
    requires = "Questie",
    frames = { "Questie_BaseFrame" } },
  { key = "castbar", label = "Cast bar",
    alias = { "cast", "cb" },
    frames = { "CastingBarFrame", "PlayerCastingBarFrame" } },
}

ns.keepByKey, ns.keepAliases = {}, {}
for _, e in ipairs(ns.keepList) do
  ns.keepByKey[e.key] = e
  ns.keepAliases[e.key] = e.key
  for _, a in ipairs(e.alias or {}) do ns.keepAliases[a] = e.key end
end

-- Is the addon this element depends on loaded? (checked at use time)
function ns.available(e)
  if not e.requires then return true end
  return _G[e.requires] ~= nil
end

-- Built-in presets (all of them hide the UI; "normal" is a reset)
ns.builtin = {
  explore    = { keep = { minimap = true, chat = true }, players = 0 },
  social     = { keep = { chat = true, player = true }, players = 3 },
  immersive  = { keep = {}, players = 0, combat = true },
  screenshot = { keep = {}, players = 0 },
}
ns.presetOrder = { "normal", "explore", "social", "immersive", "screenshot" }

-- Player name stages: 0 none, 1 own only, 2 others only, 3 own + others
ns.stageNames = { [0] = "none", "own only", "others only", "own + others" }