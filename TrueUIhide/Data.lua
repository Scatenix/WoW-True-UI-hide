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
  "ShowQuestUnitCircles",
}
-- Floating combat text: hidden with the UI unless kept (names that do not exist
-- in the client are ignored)
ns.combatTextCVars = {
  "enableFloatingCombatText", "floatingCombatTextCombatDamage",
  "floatingCombatTextCombatHealing", "floatingCombatTextCombatState",
  "floatingCombatTextEnergyGains", "floatingCombatTextReactives",
  "floatingCombatTextLowManaHealth", "floatingCombatTextHonorGains",
  "floatingCombatTextRepChanges", "floatingCombatTextDamageReduction",
  "floatingCombatTextPetMeleeDamage", "floatingCombatTextPetSpellDamage",
  "floatingCombatTextCombatLogPeriodicSpells", "floatingCombatTextFriendlyHealers",
  "floatingCombatTextAuras", "floatingCombatTextPeriodicEnergyGains",
}
for _, c in ipairs(ns.combatTextCVars) do ns.baseCVars[#ns.baseCVars + 1] = c end
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

-- Frame names that exist more than once (party members, popups, ...)
local function numbered(prefix, count, first)
  local n = {}
  for i = first or 1, count do n[#n + 1] = prefix .. i end
  return n
end

local function partyFrames()
  local n = numbered("PartyMemberFrame", 4)
  for _, f in ipairs({ "PartyFrame", "CompactPartyFrame", "CompactRaidFrameContainer",
                       "CompactRaidFrameManager" }) do n[#n + 1] = f end
  return n
end

local function lootFrames()
  local n = { "LootFrame", "GroupLootContainer", "MasterLooterFrame", "BonusRollFrame" }
  for _, f in ipairs(numbered("GroupLootFrame", 4)) do n[#n + 1] = f end
  return n
end

local function popupFrames()
  local n = numbered("StaticPopup", 4)
  for _, f in ipairs({ "ReadyCheckFrame", "PVPReadyDialog", "LFGDungeonReadyDialog",
                       "LFGDungeonReadyPopup" }) do n[#n + 1] = f end
  return n
end

-- Groups of the keep list: shown as sections in the settings panel
ns.keepGroups = {
  { key = "frames",  label = "Unit frames and minimap" },
  { key = "names",   label = "Names and nameplates" },
  { key = "windows", label = "Windows" },
  { key = "bars",    label = "Bars, chat and text" },
}

-- Elements that can stay visible while the UI is hidden, in display order
-- (grouped by `group`). `tip` is shown when hovering the checkbox.
-- Entries without "frames" are handled through CVars (`cvars` or `match`).
-- Entries with "requires" only work when that global exists (other addons).
-- "frames" can be a list of names or a function that returns names/frames;
-- names that do not exist in this client are skipped.
ns.keepList = {
  -- Unit frames and minimap
  { key = "minimap", group = "frames", label = "Minimap",
    alias = { "map", "m" },
    frames = { "MinimapCluster" } },
  { key = "player", group = "frames", label = "Player frame",
    alias = { "pf" },
    frames = { "PlayerFrame" } },
  { key = "target", group = "frames", label = "Target frame",
    alias = { "tf", "t" },
    frames = { "TargetFrame" } },
  { key = "pet", group = "frames", label = "Pet frame",
    alias = { "petframe" },
    frames = { "PetFrame" } },
  { key = "party", group = "frames", label = "Party and raid frames",
    alias = { "group", "raid" },
    frames = partyFrames },
  { key = "castbar", group = "frames", label = "Cast bar",
    alias = { "cast", "cb" },
    frames = { "CastingBarFrame", "PlayerCastingBarFrame" } },

  -- Names and nameplates
  { key = "enemyplates", group = "names", label = "Enemy nameplates",
    alias = { "plates", "nameplates", "np", "ep" } },
  { key = "friendlyplates", group = "names", label = "Friendly nameplates",
    alias = { "fplates", "fnp" },
    cvars = { "nameplateShowFriends", "nameplateShowFriendlyPlayers", "nameplateShowFriendlyNpcs" } },
  { key = "friendlynames", group = "names", label = "Friendly player names",
    alias = { "fnames", "fn" },
    cvars = { "UnitNameFriendlyPlayerName" } },
  { key = "npcnames", group = "names", label = "General NPC names",
    alias = { "npc", "npcs" },
    tip = "NPC, hostile NPC and non-combat creature names",
    cvars = { "UnitNameNPC", "UnitNameNonCombatCreatureName", "UnitNameHostleNPC" } },
  { key = "interactivenpcs", group = "names", label = "Interactive NPC names",
    alias = { "inpc", "interactive" },
    tip = "The game's setting for NPCs you can interact with. In practice this shows most friendly NPC names",
    cvars = { "UnitNameInteractiveNPC" } },
  { key = "specialnpcs", group = "names", label = "Special NPC names",
    alias = { "snpc", "special" },
    tip = "The game's setting for special friendly NPCs",
    cvars = { "UnitNameFriendlySpecialNPCName" } },
  { key = "friendlypets", group = "names", label = "Friendly pet names",
    alias = { "fpets", "pets" },
    tip = "Friendly pet, guardian, minion and totem names",
    cvars = { "UnitNameFriendlyPetName", "UnitNameFriendlyGuardianName",
              "UnitNameFriendlyMinionName", "UnitNameFriendlyTotemName" } },
  { key = "enemypets", group = "names", label = "Enemy pet names",
    alias = { "epets" },
    tip = "Enemy pet, guardian, minion and totem names",
    cvars = { "UnitNameEnemyPetName", "UnitNameEnemyGuardianName",
              "UnitNameEnemyMinionName", "UnitNameEnemyTotemName" } },
  { key = "guildtitles", group = "names", label = "Guild names and titles",
    alias = { "guild", "titles" },
    cvars = { "UnitNameGuildTitle", "UnitNamePlayerGuild", "UnitNamePlayerPVPTitle" } },
  { key = "softtarget", group = "names", label = "Soft-target highlight",
    alias = { "soft", "st" },
    tip = "The game's soft-target settings (hidden together with the UI by default)",
    match = function(c) return c:lower():sub(1, 10) == "softtarget" end },
  { key = "questcircles", group = "names", label = "Quest circles",
    alias = { "circles", "qc" },
    tip = "The circles under quest objectives in the world",
    cvars = { "ShowQuestUnitCircles" } },

  -- Windows
  { key = "npcdialogs", group = "windows", label = "NPC dialogs",
    alias = { "dialogs", "gossip" },
    tip = "Gossip and quest windows, vendors, trainers, flight maps, bank and similar",
    frames = { "GossipFrame", "QuestFrame", "MerchantFrame", "ClassTrainerFrame",
               "TrainerFrame", "TaxiFrame", "BankFrame", "ItemTextFrame",
               "QuestLogFrame", "PetStableFrame", "TabardFrame" } },
  { key = "bags", group = "windows", label = "Bags",
    alias = { "bag", "inventory" },
    tip = "Combined or separate bag windows (needed to sell items to a vendor)",
    -- the bag windows themselves follow the game's fullscreen-frame hook (Frames.lua);
    -- their container must be visible too, or the game lays the bags out wrongly
    frames = { "ContainerFrameContainer" },
    fullscreen = true },
  { key = "loot", group = "windows", label = "Loot windows",
    alias = { "looting" },
    tip = "The loot window and the group loot roll windows",
    frames = lootFrames },
  { key = "popups", group = "windows", label = "Popups and invites",
    alias = { "popup", "invites" },
    tip = "Group invites, resurrect and summon requests, duels, ready checks and queue pops",
    frames = popupFrames },
  { key = "trademail", group = "windows", label = "Trade, mail, auctions",
    alias = { "trade", "mail", "auction" },
    tip = "Trade, mail, auction house and crafting windows",
    frames = { "TradeFrame", "MailFrame", "OpenMailFrame", "AuctionFrame",
               "AuctionHouseFrame", "CraftFrame", "TradeSkillFrame", "ProfessionsFrame" } },
  { key = "charwindows", group = "windows", label = "Character windows",
    alias = { "character", "spellbook", "talents" },
    tip = "Character, spellbook, talents and friends",
    frames = { "CharacterFrame", "SpellBookFrame", "PlayerSpellsFrame", "TalentFrame",
               "PlayerTalentFrame", "FriendsFrame" } },
  { key = "worldmap", group = "windows", label = "World map",
    alias = { "bigmap", "wm" },
    tip = "The big map, opened with M",
    frames = { "WorldMapFrame" } },
  { key = "gamemenu", group = "windows", label = "Game menu and settings",
    alias = { "menu", "settings" },
    tip = "The game menu and the settings windows, also this addon's settings (/tuih config)",
    frames = { "GameMenuFrame", "SettingsPanel", "InterfaceOptionsFrame", "VideoOptionsFrame",
               "KeyBindingFrame" } },

  -- Bars, chat and text
  { key = "chat", group = "bars", label = "Chat",
    alias = { "c" },
    frames = chatNames },
  { key = "actionbars", group = "bars", label = "Action bars",
    alias = { "bars", "ab", "actionbar" },
    tip = "All action bars, including the stance and pet bars",
    frames = actionBarFrames },
  { key = "statusbars", group = "bars", label = "Experience and reputation",
    alias = { "xp", "exp", "rep" },
    frames = { "StatusTrackingBarManager", "MainStatusTrackingBarContainer",
               "SecondaryStatusTrackingBarContainer", "MainMenuExpBar", "ReputationWatchBar" } },
  { key = "buffs", group = "bars", label = "Buffs and debuffs",
    alias = { "b", "auras" },
    frames = { "BuffFrame", "TemporaryEnchantFrame" } },
  { key = "quest", group = "bars", label = "Quest tracker",
    alias = { "q", "tracker" },
    frames = { "QuestWatchFrame", "ObjectiveTrackerFrame", "WatchFrame" } },
  { key = "questie", group = "bars", label = "Questie tracker",
    alias = { "qt" },
    requires = "Questie",
    frames = { "Questie_BaseFrame" } },
  { key = "messages", group = "bars", label = "Error and zone text",
    alias = { "errors", "zonetext" },
    tip = "Error messages (\"Out of range\"), zone names and raid warnings",
    frames = { "UIErrorsFrame", "ZoneTextFrame", "SubZoneTextFrame", "RaidWarningFrame",
               "RaidBossEmoteFrame" } },
  { key = "combattext", group = "bars", label = "Floating combat text",
    alias = { "fct", "damage" },
    tip = "Damage and healing numbers in the world. Hidden by default while the UI is hidden",
    cvars = ns.combatTextCVars },
}

ns.keepByKey, ns.keepAliases = {}, {}
for _, e in ipairs(ns.keepList) do
  -- Elements that own game settings: `cvars` (names) or `match` (function)
  if e.cvars then
    e.cvarSet = {}
    for _, c in ipairs(e.cvars) do e.cvarSet[c:lower()] = true end
  end
  ns.keepByKey[e.key] = e
  ns.keepAliases[e.key] = e.key
  for _, a in ipairs(e.alias or {}) do ns.keepAliases[a] = e.key end
end

-- Is the addon this element depends on loaded? (checked at use time)
function ns.available(e)
  if not e.requires then return true end
  return _G[e.requires] ~= nil
end

-- Built-in presets (all of them hide the UI). "Back to normal" is /tuih reset.
-- Kept elements only stay as they are; player names: 0 none, 1 own, 2 others, 3 both.
ns.builtin = {
  -- Walking around: the minimap, plus what you need to loot and trade
  explore = { players = 0, keep = {
    minimap = true, loot = true, popups = true, npcdialogs = true, bags = true } },
  -- Questing: everything to find, accept and hand in quests
  questing = { players = 0, keep = {
    minimap = true, chat = true, quest = true, questcircles = true, interactivenpcs = true,
    npcdialogs = true, bags = true, loot = true, popups = true, castbar = true,
    messages = true, trademail = true, charwindows = true } },
  -- Being around other players
  social = { players = 3, keep = {
    chat = true, player = true, party = true, friendlynames = true, guildtitles = true,
    popups = true, trademail = true, npcdialogs = true } },
  -- Role-playing: names, dialogs and chat, nothing else
  roleplay = { players = 2, keep = {
    chat = true, friendlynames = true, guildtitles = true, npcnames = true, interactivenpcs = true,
    specialnpcs = true, npcdialogs = true, popups = true, loot = true } },
  -- Minimal combat HUD: your frames, bars and enemy nameplates
  minimal = { players = 0, keep = {
    player = true, target = true, castbar = true, actionbars = true, buffs = true,
    party = true, enemyplates = true, messages = true, popups = true, loot = true } },
  -- Nothing at all
  screenshot = { players = 0, keep = {} },
}
ns.presetOrder = { "explore", "questing", "social", "roleplay", "minimal", "screenshot" }

-- Name stages while hidden: players 0..3 (own / friendly players), enemies 0..3 (enemy players / hostile mobs)
ns.stageNames = { [0] = "none", "own only", "friendly players", "own + friendly players" }
ns.enemyStageNames = { [0] = "none", "enemy players", "hostile mobs", "enemy players + hostile mobs" }
