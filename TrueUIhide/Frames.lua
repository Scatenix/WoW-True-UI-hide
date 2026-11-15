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

-- Make the frame state match "UI hidden" + the keep settings
function ns.sync()
  if InCombatLockdown() then ns.state.needsSync = true return end
  local hidden = not UIParent:IsShown()
  for _, e in ipairs(ns.keepList) do
    if e.frames and ns.available(e) then
      local want = hidden and TUIHDB.keep[e.key] and not ns.state.shotMode
      for _, f in ipairs(framesFor(e)) do
        if want then detach(f) else attach(f) end
      end
    end
  end
end

-- Enemy nameplates are a setting, not a frame
function ns.syncPlates()
  if UIParent:IsShown() or InCombatLockdown() then return end
  if TUIHDB.keep.enemyplates then
    local v = TUIHDB.saved and TUIHDB.saved.nameplateShowEnemies
    if v ~= nil then pcall(SetCVar, "nameplateShowEnemies", v) end
  else
    pcall(SetCVar, "nameplateShowEnemies", "0")
  end
end

function ns.applyUI(show)
  UIParent:SetShown(show)
  ns.sync()
end