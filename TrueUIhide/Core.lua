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

-- SavedVariables are only available after ADDON_LOADED
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" then
    if name ~= ADDON_NAME then return end
    TUIHDB = TUIHDB or {}
    TUIHDB.keep = TUIHDB.keep or {}
    TUIHDB.presets = TUIHDB.presets or {}
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
    if TUIHDB and TUIHDB.saved and UIParent:IsShown() then
      ns.log("Saved settings from the last session exist. Run /tuih on to restore them.")
    end
    if TUIHDB and TUIHDB.combatNotice then
      TUIHDB.combatNotice = nil
      ns.log("\"Show the UI during combat\" is on by default. " .. ns.COMBAT_WARNING
        .. " Turn it off with /tuih combat.")
    end
  end
end)

ns.log("Loaded. Hover the [TUIH] tag for commands.")