-- CVars: save, hide and restore settings; player name stages
local _, ns = ...

function ns.getAllCommands()
  local fn = (C_Console and C_Console.GetAllCommands) or ConsoleGetAllCommands
  if not fn then return nil end
  local ok, list = pcall(fn)
  if ok and type(list) == "table" then return list end
end

-- Build the list of CVars to hide/restore (cached)
local cached
function ns.cvarList()
  if cached then return cached end
  local set, names = {}, {}
  local function add(c)
    if not set[c] and GetCVar(c) ~= nil then
      set[c] = true
      names[#names + 1] = c
    end
  end
  for _, c in ipairs(ns.baseCVars) do add(c) end
  local list = ns.getAllCommands()
  if list then
    for _, info in ipairs(list) do
      local n = info.command or info.name
      if n then
        local lower = n:lower()
        for _, p in ipairs(ns.prefixes) do
          if lower:sub(1, #p) == p then add(n) break end
        end
      end
    end
  end
  cached = names
  return names
end

function ns.isPlate(c)
  return c:lower():sub(1, 9) == "nameplate"
end

function ns.isSoftTarget(c)
  return c:lower():sub(1, 10) == "softtarget"
end

-- Merge missing values so a partial restore never loses the original state
function ns.snapshot()
  TUIHDB.saved = TUIHDB.saved or {}
  for _, c in ipairs(ns.cvarList()) do
    if TUIHDB.saved[c] == nil then TUIHDB.saved[c] = GetCVar(c) end
  end
end

-- CVar values come back as strings and may be formatted differently than
-- what was set ("0.5" vs "0.500000"), so compare numerically when possible
local function sameValue(a, b)
  if a == nil or b == nil then return false end
  if tostring(a) == tostring(b) then return true end
  local x, y = tonumber(a), tonumber(b)
  return x ~= nil and y ~= nil and math.abs(x - y) < 1e-6
end

-- What the addon itself last set, per CVar (runtime only). On restore, a
-- CVar whose current value differs was changed by the player in the
-- meantime (menu, /console): their value is kept.
local applied = {}

-- Set a CVar and check that it really changed. pcall alone is not enough:
-- blocked actions (combat) usually do not raise an error. Returns true on success.
-- isRestore: the value is being put back, so it is no longer "ours".
function ns.setCVar(c, v, isRestore)
  pcall(SetCVar, c, v)
  local ok = sameValue(GetCVar(c), v)
  if ok then applied[c] = (not isRestore) and v or nil end
  return ok
end

-- Restore the saved state; values that could not be restored are kept
-- so that a later call (after combat, next login) can finish the job
function ns.restore(quiet)
  local s = TUIHDB.saved
  if s then
    local left, pending = {}, false
    for c, v in pairs(s) do
      local now = GetCVar(c)
      if now == nil then
        -- CVar no longer exists in this client: nothing to restore
      elseif applied[c] ~= nil and not sameValue(now, applied[c]) then
        -- The player changed it while the UI was hidden: keep their value
        applied[c] = nil
        ns.info("Kept your change: " .. c .. " = " .. tostring(now))
      elseif ns.isPlate(c) and InCombatLockdown() then
        left[c], pending = v, true
      elseif not ns.setCVar(c, v, true) then
        left[c], pending = v, true
      end
    end
    TUIHDB.saved = pending and left or nil
    if not pending then applied = {} end
    if pending and not quiet then
      ns.log("Some settings could not be restored (combat?). Run /tuih again after combat.")
    end
    return not pending
  elseif not UIParent:IsShown() then
    -- Hidden but nothing saved: fall back to showing player names
    for _, c in ipairs({ "UnitNameOwn", "UnitNameFriendlyPlayerName", "UnitNameEnemyPlayerName" }) do
      ns.setCVar(c, "1")
    end
  end
  return true
end

function ns.hideAll()
  if TUIHDB.saved == nil then applied = {} end  -- a new hide starts clean
  ns.snapshot()  -- adds only values that are not saved yet
  for _, c in ipairs(ns.cvarList()) do
    local skip = (c == "nameplateShowEnemies" and TUIHDB.keep.enemyplates)
      or (ns.isSoftTarget(c) and TUIHDB.keep.softtarget)
      or (ns.isPlate(c) and InCombatLockdown())
    local v = GetCVar(c)
    if v ~= nil and v ~= "0" and not skip then
      ns.setCVar(c, "0")
    elseif v == "0" and not skip then
      applied[c] = "0"  -- already off: still notice if the player turns it on
    end
  end
end

function ns.getStage()
  local own = GetCVar("UnitNameOwn") == "1"
  local others = GetCVar("UnitNameFriendlyPlayerName") == "1"
    or GetCVar("UnitNameEnemyPlayerName") == "1"
  return (own and 1 or 0) + (others and 2 or 0)
end

function ns.setStage(i)
  i = tonumber(i) or 0
  if i < 0 or i > 3 then i = 0 end
  local o = (i % 2 == 1) and "1" or "0"
  local p = (i >= 2) and "1" or "0"
  ns.setCVar("UnitNameOwn", o)
  ns.setCVar("UnitNameFriendlyPlayerName", p)
  ns.setCVar("UnitNameEnemyPlayerName", p)
end

-- Player nameplates follow the name cycle: always off.
-- Enemy plates are left alone when "Keep: Enemy nameplates" is on.
-- The original values are saved so the normal restore brings them back.
function ns.hidePlayerPlates()
  if InCombatLockdown() then return end
  TUIHDB.saved = TUIHDB.saved or {}
  for _, c in ipairs({ "nameplateShowFriends", "nameplateShowEnemies" }) do
    local skip = (c == "nameplateShowEnemies" and TUIHDB.keep.enemyplates)
    if not skip then
      if TUIHDB.saved[c] == nil then TUIHDB.saved[c] = GetCVar(c) end
      ns.setCVar(c, "0")
    end
  end
end