-- luacheck config for True UI Hide (World of Warcraft addon, Lua 5.1)
std = "lua51"
max_line_length = false

-- Globals the addon defines or changes
globals = {
  "TUIHDB",
  "SLASH_TUIH1",
  "SlashCmdList",
  "StaticPopupDialogs",
}

-- Binding labels and the functions called from Bindings.xml are global by design
ignore = {
  "111/BINDING_.*",
  "111/TUIH_.*",
  "212",  -- unused arguments (event handlers and script callbacks)
  "213",  -- unused loop variables
}

-- Game API the addon reads (provided by the client, not defined here)
read_globals = {
  "CANCEL", "C_Console", "C_Timer", "ConsoleGetAllCommands",
  "ContainerFrame_ClearFullScreenFrame", "ContainerFrame_SetFullScreenFrame",
  "CreateFrame", "DELETE", "FCF_OpenTemporaryWindow", "GameMenuFrame", "GameMenuFrame_Show", "GameTooltip", "GetTime", "UIErrorsFrame",
  "GetCVar", "GetCVarDefault", "GetCursorPosition", "GetMouseFoci", "GetMouseFocus",
  "HideUIPanel", "InCombatLockdown", "InterfaceOptionsFrame",
  "InterfaceOptionsFrame_OpenToCategory", "InterfaceOptions_AddCategory",
  "IsMouselooking", "Minimap", "MouselookStart", "MouselookStop", "NUM_CHAT_WINDOWS", "OKAY",
  "Screenshot", "SetCVar", "Settings", "SettingsPanel", "StaticPopup_Show",
  "UIDropDownMenu_AddButton", "UIDropDownMenu_CreateInfo", "UIDropDownMenu_Initialize",
  "UIDropDownMenu_SetText", "UIDropDownMenu_SetWidth", "UIParent", "WorldFrame",
  "hooksecurefunc", "strsplit",
}
