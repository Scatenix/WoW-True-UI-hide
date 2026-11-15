-- Commands: slash commands
local _, ns = ...

SLASH_TUIH1 = "/tuih"
SlashCmdList["TUIH"] = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  if cmd == "" then ns.toggle()
  elseif cmd == "on" then ns.userSetAll(true)
  elseif cmd == "off" then ns.userSetAll(false)
  elseif cmd == "p" or cmd == "players" then ns.cyclePlayers()
  elseif cmd == "diff" or cmd == "d" then ns.diff()
  elseif cmd == "status" or cmd == "s" then ns.status()
  elseif cmd == "help" or cmd == "h" or cmd == "?" then ns.showHelp()
  elseif cmd == "config" or cmd == "cfg" or cmd == "options" or cmd == "o" then ns.openConfig()
  elseif cmd == "combat" then ns.toggleCombat()
  elseif cmd == "shot" or cmd == "ss" then ns.shot()
  elseif cmd == "reset" then ns.reset()
  elseif cmd == "preset" then ns.presetCommand(arg)
  elseif ns.keepAliases[cmd] then ns.toggleKeep(ns.keepAliases[cmd])
  elseif cmd == "normal" or ns.builtin[cmd] or (TUIHDB.presets and TUIHDB.presets[cmd]) then ns.applyPreset(cmd)
  else ns.log("Unknown command. Run /tuih help.") end
end

SLASH_TUIHP1 = "/tuihp"
SlashCmdList["TUIHP"] = function() ns.cyclePlayers() end