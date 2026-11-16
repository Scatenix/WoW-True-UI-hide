-- Commands: slash commands
--
-- Root level (most used):  /tuih, on, off, players, shot, mouselook, status,
--                          config, reset, wipe, help, diff
-- Groups:                  /tuih toggle <element>     elements kept visible
--                          /tuih preset <name | save | delete | list>
--                          /tuih set <combat | mouselook>   settings
local _, ns = ...

local function firstWord(s)
  return s:match("^(%S+)")
end

-- /tuih toggle [element]
local function toggleCommand(arg)
  local word = firstWord(arg)
  if not word then
    local names = {}
    for _, e in ipairs(ns.keepList) do
      if ns.available(e) then names[#names + 1] = e.key end
    end
    ns.log("Usage: /tuih toggle <element>. Elements: " .. table.concat(names, ", "))
    return
  end
  local key = ns.keepAliases[word]
  if key then
    ns.toggleKeep(key)
  else
    ns.log("Unknown element: " .. word .. ". Run /tuih toggle for the list.")
  end
end

-- /tuih set <combat | mouselook | icon | shotcombat | dot | cyclemessage | verbose>
local function setCommand(arg)
  local word = firstWord(arg)
  if word == "combat" then
    ns.toggleCombat()
  elseif word == "mouselook" or word == "look" or word == "ml" then
    ns.toggleMouselookAuto()
  elseif word == "icon" or word == "minimap" then
    ns.toggleMinimapIcon()
  elseif word == "shotcombat" then
    ns.toggleShotCombat()
  elseif word == "cyclemessage" or word == "cycle" then
    ns.toggleCycleMessage()
  elseif word == "dot" or word == "indicator" then
    ns.toggleIndicator()
  elseif word == "verbose" or word == "chat" then
    ns.toggleVerbose()
  else
    ns.log("Usage: /tuih set combat | mouselook | icon | shotcombat | dot | cyclemessage | verbose")
  end
end

-- Command name -> handler (aliases point to the same handler)
local handlers = {}
local function add(fn, ...)
  for _, name in ipairs({ ... }) do handlers[name] = fn end
end

add(function() ns.userSetAll(true) end, "on")
add(function() ns.userSetAll(false) end, "off")
add(function() ns.cyclePlayers() end, "players", "p")
add(function() ns.shot() end, "shot", "ss")
add(function() ns.toggleMouselook() end, "mouselook", "look", "ml")
add(function() ns.status() end, "status", "s")
add(function() ns.openConfig() end, "config", "cfg", "options", "o")
add(function() ns.reset() end, "reset")
add(function(arg)
  if arg == "confirm" then
    ns.wipeAll()
  else
    ns.log("This deletes ALL True UI Hide data (presets, options) after restoring your game settings. To continue, run /tuih wipe confirm")
  end
end, "wipe")
add(function() ns.showHelp() end, "help", "h", "?")
add(function() ns.diff() end, "diff", "d")
add(toggleCommand, "toggle", "keep", "k")
add(function(arg) ns.presetCommand(arg) end, "preset", "presets", "pr")
add(setCommand, "set", "option", "opt")

SLASH_TUIH1 = "/tuih"
SlashCmdList["TUIH"] = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  if cmd == "" then ns.toggle() return end
  local fn = handlers[cmd]
  if fn then fn(arg) return end
  ns.log("Unknown command. Run /tuih help.")
end
