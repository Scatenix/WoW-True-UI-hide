-- Core: shared namespace, logging, saved variables, login hooks
local ADDON_NAME, ns = ...

ns.name = ADDON_NAME

-- Runtime state shared between modules
ns.state = {
  peek = {},          -- peek.mode = "show" | "hide", peek.stage
  shotMode = false,
  shotBusy = false,
  needsSync = false,  -- a frame sync was blocked by combat
  autoShown = false,  -- UI was shown automatically by the combat option
  autoStage = nil,
  pending = nil,      -- UI change queued until combat ends
}

-- Functions that run on PLAYER_LOGIN (other modules add to this list)
ns.onLogin = {}

-- Default for "Show the UI during combat"
ns.COMBAT_SHOW_DEFAULT = true
ns.COMBAT_WARNING = "The game may block showing the UI in combat. If nothing happens, the UI stays hidden until combat ends."

function ns.copy(t)
  local c = {}
  for k, v in pairs(t or {}) do c[k] = v end
  return c
end

function ns.link(text, key)
  return "|cffa335ee|Haddon:TUIH:" .. key .. "|h[" .. text .. "]|h|r"
end

-- Every chat message gets a hoverable [TUIH] tag
function ns.log(msg, key)
  print(ns.link("TUIH", key or "status") .. " " .. msg)
end

-- Make sure the saved variables have the expected shape, so a corrupted
-- or hand-edited file cannot cause errors in every command
local function sanitize()
  if type(TUIHDB) ~= "table" then TUIHDB = {} end
  if type(TUIHDB.keep) ~= "table" then TUIHDB.keep = {} end
  if type(TUIHDB.presets) ~= "table" then TUIHDB.presets = {} end
  if type(TUIHDB.combatShow) ~= "boolean" then TUIHDB.combatShow = nil end

  -- Saved CVar values: string name -> string value
  if type(TUIHDB.saved) ~= "table" then
    TUIHDB.saved = nil
  else
    for c, v in pairs(TUIHDB.saved) do
      if type(c) ~= "string" or type(v) ~= "string" then TUIHDB.saved[c] = nil end
    end
    if next(TUIHDB.saved) == nil then TUIHDB.saved = nil end
  end

  -- Custom presets: name -> { keep = table, players = 0..3, combat = boolean|nil }
  for name, p in pairs(TUIHDB.presets) do
    if type(name) ~= "string" or type(p) ~= "table" then
      TUIHDB.presets[name] = nil
    else
      if type(p.keep) ~= "table" then p.keep = {} end
      local n = tonumber(p.players)
      p.players = (n and n >= 0 and n <= 3) and math.floor(n) or 0
      if p.combat ~= nil and type(p.combat) ~= "boolean" then p.combat = nil end
    end
  end
end

-- Put the player's original CVars back. Used on logout/reload and at login,
-- so the game is never left with names/nameplates switched off.
local function restoreSaved(quiet)
  if not (TUIHDB and TUIHDB.saved) then return false end
  local ok, err = pcall(ns.restore, true)
  if not ok then
    if not quiet then ns.log("Could not restore saved settings: " .. tostring(err)) end
    return false
  end
  return TUIHDB.saved == nil
end

-- SavedVariables are only available after ADDON_LOADED
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_LOGOUT")
loader:SetScript("OnEvent", function(_, event, name)
  if event == "PLAYER_LOGOUT" then
    -- Also fires on /reload. The hidden state does not survive either way,
    -- so leave the CVars the way the player had them.
    restoreSaved(true)
    return
  end
  if event == "ADDON_LOADED" then
    if name ~= ADDON_NAME then return end
    sanitize()
    -- Migrate the old minimap flag
    if TUIHDB.keepMinimap ~= nil then
      TUIHDB.keep.minimap = TUIHDB.keepMinimap
      TUIHDB.keepMinimap = nil
    end
    -- Show the UI during combat: on by default, with a one-time warning
    if TUIHDB.combatShow == nil then
      TUIHDB.combatShow = ns.COMBAT_SHOW_DEFAULT
      TUIHDB.combatNotice = true
    end
    loader:UnregisterEvent("ADDON_LOADED")
  else  -- PLAYER_LOGIN
    for _, fn in ipairs(ns.onLogin) do fn() end
    -- Leftovers from a session that ended without a restore (crash, failed
    -- restore in combat): put the original settings back automatically
    if TUIHDB and TUIHDB.saved and UIParent:IsShown() then
      if restoreSaved(false) then
        ns.log("Restored your settings from the last session.")
      else
        ns.log("Some settings from the last session could not be restored yet. Run /tuih on to retry.")
      end
    end
    if TUIHDB and TUIHDB.combatNotice then
      TUIHDB.combatNotice = nil
      ns.log("\"Show the UI during combat\" is on by default. " .. ns.COMBAT_WARNING
        .. " Turn it off with /tuih combat.")
    end
  end
end)

ns.log("Loaded. Hover the [TUIH] tag for commands.")