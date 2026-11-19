-- Frames: keep elements visible while UIParent is hidden
local _, ns = ...

local detached = {}  -- [frame] = { scale = original scale, points = original anchors }

-- Resolve an element's frames; entries can be names or frame objects
local function framesFor(e)
  local names = e.frames
  if type(names) == "function" then names = names() end
  local out, seen = {}, {}
  for _, n in ipairs(names or {}) do
    local f = type(n) == "string" and _G[n] or n
    if type(f) == "table" and f.SetParent and not seen[f] then
      seen[f] = true
      out[#out + 1] = f
    end
  end
  return out
end

local function savePoints(f)
  local pts = {}
  for i = 1, f:GetNumPoints() do
    local point, rel, relPoint, x, y = f:GetPoint(i)
    pts[i] = { point, rel, relPoint, x, y }
  end
  return pts
end

-- Re-apply anchors; a nil anchor target means "my parent", so pin it to UIParent
local function loadPoints(f, pts, pinToUIParent)
  f:ClearAllPoints()
  for _, a in ipairs(pts) do
    local rel = a[2]
    if rel == nil and pinToUIParent then rel = UIParent end
    f:SetPoint(a[1], rel, a[3], a[4], a[5])
  end
end

-- Move a frame to WorldFrame while keeping its on-screen size and position
local function detach(f)
  if detached[f] or f:GetParent() ~= UIParent then return end
  local scale = f:GetScale()
  local pts = savePoints(f)
  local ratio = UIParent:GetEffectiveScale() / WorldFrame:GetEffectiveScale()
  detached[f] = { scale = scale, points = pts }
  f:SetParent(WorldFrame)
  f:SetScale(scale * ratio)
  loadPoints(f, pts, true)
end

local function attach(f)
  local st = detached[f]
  if not st then return end
  f:SetParent(UIParent)
  f:SetScale(st.scale)
  loadPoints(f, st.points, false)
  detached[f] = nil
end

-- Bags: the game refuses to open them while UIParent is hidden. It has a
-- hook for that: it can use another frame as the "fullscreen" parent.
-- A stand-in for UIParent (same size and scale), so the bags keep their look.
local fullscreenSet = false
local standIn
local function syncFullscreen(want)
  if want and not fullscreenSet and ContainerFrame_SetFullScreenFrame then
    standIn = standIn or CreateFrame("Frame", nil, WorldFrame)
    standIn:ClearAllPoints()
    standIn:SetScale(UIParent:GetEffectiveScale() / WorldFrame:GetEffectiveScale())
    standIn:SetAllPoints(UIParent)
    ContainerFrame_SetFullScreenFrame(standIn)
    fullscreenSet = true
  elseif not want and fullscreenSet then
    if ContainerFrame_ClearFullScreenFrame then ContainerFrame_ClearFullScreenFrame() end
    fullscreenSet = false
  end
end

-- Frames the player added by name (TUIHDB.customFrames[name] = true)
local DEFAULT_CUSTOM_LIMIT = 100
ns.DEFAULT_CUSTOM_LIMIT = DEFAULT_CUSTOM_LIMIT
-- Only a safety limit against runaway lists; the player can raise it
function ns.customLimit() return TUIHDB.customLimit or DEFAULT_CUSTOM_LIMIT end
-- Whether a listed frame is kept lives in TUIHDB.keep, so presets include it
local function customKey(name) return "frame:" .. name end
function ns.customKept(name) return TUIHDB.keep[customKey(name)] and true or false end
local NEVER_KEEP = { UIParent = true, WorldFrame = true }

local function frameByName(name)
  local f = _G[name]
  if type(f) == "table" and f.SetParent and f.GetParent then return f end
end

function ns.customFrameList()
  local list = {}
  for name in pairs(TUIHDB.customFrames or {}) do list[#list + 1] = name end
  table.sort(list)
  return list
end

-- Returns true on success
function ns.addCustomFrame(name)
  name = (name or ""):match("^%s*(.-)%s*$")
  if name == "" or #name > 64 or not name:match("^[%w_]+$") then
    ns.error("Enter a frame name (letters, digits and _ only). Tip: /tuih keepframe pick")
    return false
  end
  if NEVER_KEEP[name] then
    ns.error("That frame cannot be kept: " .. name)
    return false
  end
  local f = frameByName(name)
  if not f then
    ns.error("No frame named " .. name .. " (names are case-sensitive; the window may need to be opened once first).")
    return false
  end
  TUIHDB.customFrames = TUIHDB.customFrames or {}
  if TUIHDB.customFrames[name] then
    ns.error(name .. " is already in your list.")
    return false
  end
  if #ns.customFrameList() >= ns.customLimit() then
    ns.error("Your list is full (" .. ns.customLimit() .. " windows). Remove one, or raise the limit in the settings.")
    return false
  end
  TUIHDB.customFrames[name] = true
  TUIHDB.keep[customKey(name)] = true
  ns.log("Keeping " .. name .. " visible.")
  ns.sync()
  if ns.refreshOptions then ns.refreshOptions() end
  return true
end

function ns.removeCustomFrame(name)
  if not (TUIHDB.customFrames and TUIHDB.customFrames[name]) then
    ns.log(tostring(name) .. " is not in your list.")
    return false
  end
  TUIHDB.customFrames[name] = nil
  TUIHDB.keep[customKey(name)] = nil
  ns.sync()  -- puts the frame back unless an element still keeps it
  ns.log("Removed " .. name .. ".")
  if ns.refreshOptions then ns.refreshOptions() end
  return true
end

-- Turn keeping a listed frame on or off (part of the current keep settings)
function ns.setCustomKeep(name, value)
  if not (TUIHDB.customFrames and TUIHDB.customFrames[name]) then
    ns.log(tostring(name) .. " is not in your list. Add it with /tuih keepframe add " .. tostring(name))
    return false
  end
  TUIHDB.keep[customKey(name)] = value or nil
  ns.sync()
  return true
end

function ns.setCustomKeepToggle(name)
  return ns.setCustomKeep(name, not ns.customKept(name))
end

-- Walk up from the frame under the mouse to the window that sits directly on
-- UIParent. Returns the frame, or nil and a reason.
local function frameUnderMouse()
  local f
  if GetMouseFoci then f = (GetMouseFoci())[1] elseif GetMouseFocus then f = GetMouseFocus() end
  if not f or f == WorldFrame or f == UIParent then
    return nil, "No window under the mouse."
  end
  while f and f ~= UIParent and f ~= WorldFrame do
    if detached[f] then return nil, "That window is already kept visible by an element." end
    local p = f:GetParent()
    if p == UIParent then return f end
    f = p
  end
  return nil, "That is not part of the game UI (or it is already visible)."
end

-- Add the window under the mouse to the list
function ns.pickFrame()
  local f, why = frameUnderMouse()
  if not f then ns.error(why) return end
  local name = f:GetName()
  if not name then
    ns.error("That window has no name, so it cannot be kept.")
    return
  end
  ns.addCustomFrame(name)
end

-- Same, after a few seconds, so there is time to point at the window
function ns.pickFrameLater(seconds)
  seconds = seconds or 3
  ns.log("Point the mouse at the window you want to keep. Picking in " .. seconds .. " seconds...")
  C_Timer.After(seconds, ns.pickFrame)
end

-- Make the frame state match "UI hidden" + the keep settings
function ns.sync()
  if InCombatLockdown() then ns.state.needsSync = true return end
  local hidden = not UIParent:IsShown()
  local active = hidden and not ns.state.shotMode
  -- One pass over all frames: a frame stays moved if ANY element or entry of
  -- the player's own list wants it (the same frame can be in both)
  local wanted, all = {}, {}
  local function consider(f, want)
    if wanted[f] == nil then all[#all + 1] = f end
    wanted[f] = wanted[f] or want or false
  end
  for _, e in ipairs(ns.keepList) do
    if e.fullscreen then
      syncFullscreen(active and TUIHDB.keep[e.key])
    end
    if e.frames and ns.available(e) then
      local want = active and TUIHDB.keep[e.key] and true or false
      for _, f in ipairs(framesFor(e)) do consider(f, want) end
    end
  end
  for name in pairs(TUIHDB.customFrames or {}) do
    local f = frameByName(name)
    if f then consider(f, active and TUIHDB.keep[customKey(name)] and true or false) end
  end
  for f in pairs(detached) do consider(f, false) end  -- e.g. just removed from the list
  for _, f in ipairs(all) do
    if wanted[f] then detach(f) else attach(f) end
  end
end

-- Settings owned by keep elements follow those options while hidden: kept =
-- original values back, not kept = off. The player-name settings are set by
-- the name stage instead.
local stageCVar = { unitnameown = true, unitnamefriendlyplayername = true, unitnameenemyplayername = true }
function ns.syncKeptCVars()
  for _, c in ipairs(ns.cvarList()) do
    if ns.ownsCVar(c) then
      if ns.isKept(c) then
        local v = TUIHDB.saved and TUIHDB.saved[c]
        if v ~= nil then ns.setCVar(c, v) end
      elseif not stageCVar[c:lower()] and GetCVar(c) ~= "0" then
        ns.setCVar(c, "0")
      end
    end
  end
  ns.setStage(TUIHDB.playerNames or 0)
end

-- Enemy nameplates and the settings of keep elements are settings, not frames
function ns.syncPlates()
  if UIParent:IsShown() or InCombatLockdown() then return end
  ns.syncKeptCVars()
  if TUIHDB.keep.enemyplates then
    local v = TUIHDB.saved and TUIHDB.saved.nameplateShowEnemies
    if v ~= nil then ns.setCVar("nameplateShowEnemies", v) end
  else
    ns.setCVar("nameplateShowEnemies", "0")
  end
end

function ns.applyUI(show)
  UIParent:SetShown(show)
  ns.sync()
  -- Optional: enter mouselook together with hiding the UI, leave it when shown
  if TUIHDB.mouselookAuto then ns.setMouselook(not show) end
end

-- True while any frame is still moved out of UIParent
function ns.hasDetached()
  return fullscreenSet or next(detached) ~= nil
end

-- Windows that load on demand (auction house, talents, ...) only exist after
-- their addon loads: pick them up while the UI is hidden
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
  if TUIHDB and not UIParent:IsShown() then ns.sync() end
end)
