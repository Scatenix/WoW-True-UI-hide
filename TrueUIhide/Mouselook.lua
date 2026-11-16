-- Mouselook (right-click style): the mouse steers the camera and the cursor is
-- hidden, like holding the right mouse button. While it
-- is active you cannot click UI elements (a right-click ends it).
-- A left-click style (camera orbit only) is not possible: the functions that
-- simulate the left mouse button are protected and cannot be used by addons.
local _, ns = ...

ns.MOUSELOOK_INFO = "Right-click ends mouselook and brings the cursor back. A keybind can also toggle it."

local function supported()
  return MouselookStart and MouselookStop and IsMouselooking
end

function ns.setMouselook(on)
  if not supported() then return end
  if on then
    if not IsMouselooking() then MouselookStart() end
  elseif IsMouselooking() then
    MouselookStop()
  end
end

-- Independent toggle (keybind / command); works whether or not the UI is hidden
function ns.toggleMouselook()
  if not supported() then
    ns.log("Mouselook is not available in this client.", "toggle")
    return
  end
  local on = not IsMouselooking()
  ns.setMouselook(on)
  ns.log("Mouselook (right-click style): " .. (on and "on" or "off"), "toggle")
end

-- Setting: enter mouselook automatically whenever the UI gets hidden
function ns.setMouselookAuto(v)
  TUIHDB.mouselookAuto = v and true or false
  -- Apply right away if the UI is already hidden
  if not UIParent:IsShown() then ns.setMouselook(TUIHDB.mouselookAuto) end
end

function ns.toggleMouselookAuto()
  ns.setMouselookAuto(not TUIHDB.mouselookAuto)
  ns.log("Mouselook while the UI is hidden: " .. (TUIHDB.mouselookAuto and "on" or "off"), "toggle")
  if TUIHDB.mouselookAuto then ns.log(ns.MOUSELOOK_INFO, "toggle") end
end
