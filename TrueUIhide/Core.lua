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
  autoEnemies = nil,
  pending = nil,      -- UI change queued until combat ends
}

-- Functions that run on PLAYER_LOGIN (other modules add to this list)
ns.onLogin = {}

-- Default for "Show the UI during combat"
ns.COMBAT_SHOW_DEFAULT = true
-- Screenshot: wait before taking it and after it (seconds), configurable
ns.SHOT_BEFORE_DEFAULT = 0.1
ns.SHOT_AFTER_DEFAULT = 0.1
ns.SHOT_WAIT_MIN = 0.1
ns.SHOT_WAIT_MAX = 3
-- On-screen messages: how long the text stays before it fades (seconds)
ns.TOAST_SECONDS_DEFAULT = 3
ns.TOAST_SECONDS_MIN = 0
ns.TOAST_SECONDS_MAX = 10
ns.SHOT_COMBAT_WARNING = "If you turn this off, the UI stays hidden when combat starts during a screenshot, and may stay hidden until combat ends."
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

-- Routine confirmations ("UI on", "Preset: x", ...): only shown when the
-- player opted in with the "verbose" setting. Everything else uses ns.log.
function ns.info(msg, key)
  if TUIHDB and TUIHDB.verbose then ns.log(msg, key) end
end

-- Errors for things the player tried to do (a refused action, an invalid
-- name): shown in a dialog so they are not missed. Popups are children of
-- UIParent and invisible while the UI is hidden, so then (and with the verbose
-- setting on) the message also goes to the chat.
StaticPopupDialogs["TUIH_ERROR"] = {
  text = "|cffa335eeTrue UI Hide|r\n\n%s",
  button1 = OKAY or "OK",
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

function ns.error(msg, key)
  local shown = UIParent and UIParent:IsShown() and StaticPopup_Show ~= nil
  if shown then StaticPopup_Show("TUIH_ERROR", msg) end
  if not shown or (TUIHDB and TUIHDB.verbose) then ns.log(msg, key) end
end

function ns.toggleVerbose()
  TUIHDB.verbose = not TUIHDB.verbose
  ns.log("Events in chat: " .. (TUIHDB.verbose and "on" or "off"), "toggle")
end

-- Make sure the saved variables have the expected shape, so a corrupted
-- or hand-edited file cannot cause errors in every command
local function sanitize()
  if type(TUIHDB) ~= "table" then TUIHDB = {} end
  if type(TUIHDB.keep) ~= "table" then TUIHDB.keep = {} end
  if type(TUIHDB.presets) ~= "table" then TUIHDB.presets = {} end
  if type(TUIHDB.combatShow) ~= "boolean" then TUIHDB.combatShow = nil end
  if type(TUIHDB.mouselookAuto) ~= "boolean" then TUIHDB.mouselookAuto = false end
  if type(TUIHDB.shotCombatShow) ~= "boolean" then TUIHDB.shotCombatShow = true end
  for key, default in pairs({ shotBefore = ns.SHOT_BEFORE_DEFAULT, shotAfter = ns.SHOT_AFTER_DEFAULT }) do
    local v = tonumber(TUIHDB[key])
    if not v or v < ns.SHOT_WAIT_MIN or v > ns.SHOT_WAIT_MAX then v = default end
    TUIHDB[key] = v
  end
  if type(TUIHDB.welcomed) ~= "boolean" then TUIHDB.welcomed = nil end
  if type(TUIHDB.verbose) ~= "boolean" then TUIHDB.verbose = false end
  if type(TUIHDB.toasts) ~= "boolean" then TUIHDB.toasts = true end
  do
    local n = tonumber(TUIHDB.toastSeconds)
    if n and n >= ns.TOAST_SECONDS_MIN and n <= ns.TOAST_SECONDS_MAX then
      TUIHDB.toastSeconds = n
    else
      TUIHDB.toastSeconds = nil
    end
  end
  for _, key in ipairs({ "playerNames", "enemyNames" }) do
    local n = tonumber(TUIHDB[key])
    TUIHDB[key] = (n and n >= 0 and n <= 3) and math.floor(n) or 0
  end
  if type(TUIHDB.customFrames) ~= "table" then TUIHDB.customFrames = {} end
  for name, v in pairs(TUIHDB.customFrames) do
    if type(name) ~= "string" or v ~= true or not name:match("^[%w_]+$") or #name > 64 then
      TUIHDB.customFrames[name] = nil
    end
  end
  do
    local n = tonumber(TUIHDB.customLimit)
    TUIHDB.customLimit = (n and n >= 1 and n <= 10000) and math.floor(n) or nil
  end
  if type(TUIHDB.indicator) ~= "boolean" then TUIHDB.indicator = true end
  if type(TUIHDB.minimapIcon) ~= "boolean" then TUIHDB.minimapIcon = true end
  if type(TUIHDB.minimapAngle) ~= "number" then TUIHDB.minimapAngle = nil end

  -- Saved CVar values: string name -> string value
  if type(TUIHDB.saved) ~= "table" then
    TUIHDB.saved = nil
  else
    for c, v in pairs(TUIHDB.saved) do
      if type(c) ~= "string" or type(v) ~= "string" then TUIHDB.saved[c] = nil end
    end
    if next(TUIHDB.saved) == nil then TUIHDB.saved = nil end
  end

  -- Custom presets: name -> { keep = table, players = 0..3, enemies = 0..3, combat = boolean|nil }
  for name, p in pairs(TUIHDB.presets) do
    if type(name) ~= "string" or type(p) ~= "table" then
      TUIHDB.presets[name] = nil
    else
      if type(p.keep) ~= "table" then p.keep = {} end
      local n = tonumber(p.players)
      p.players = (n and n >= 0 and n <= 3) and math.floor(n) or 0
      local e = tonumber(p.enemies)
      p.enemies = (e and e >= 0 and e <= 3) and math.floor(e) or 0
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

-- Sets up TUIHDB: validates it, applies defaults. Also used after a wipe.
function ns.initDB()
  sanitize()
  -- Show the UI during combat: on by default, with a one-time warning
  if TUIHDB.combatShow == nil then
    TUIHDB.combatShow = ns.COMBAT_SHOW_DEFAULT
    TUIHDB.combatNotice = true
  end
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
    ns.initDB()
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
    -- Welcome message on the very first load only
    if not TUIHDB.welcomed then
      TUIHDB.welcomed = true
      ns.log("Loaded. Hover the [TUIH] tag for basic commands or run /tuih help")
    end
    if TUIHDB and TUIHDB.combatNotice then
      TUIHDB.combatNotice = nil
      ns.log("\"Show the UI during combat\" is on by default. " .. ns.COMBAT_WARNING
        .. " Turn it off with /tuih set combat.")
    end
  end
end)
