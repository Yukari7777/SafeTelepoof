name = "Safe Telepoof"
version = "1.1.2.1"
description = "Stop wasting your lazy explorer's durability!\n\nWhile holding lazy explorer:\n-  +  to telepoof\n-  +  to cancel"
author = "Yukari7777"
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

all_clients_require_mod = false
client_only_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

priority = 0

folder_name = folder_name or ""
if folder_name:find("SafeTelepoof") then
    name = name.." - local"
end

local Keys = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "PERIOD", "SLASH", "SEMICOLON", "TILDE", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "INSERT", "DELETE", "HOME", "END", "PAGEUP", "PAGEDOWN", "MINUS", "EQUALS", "BACKSPACE", "CAPSLOCK", "SCROLLOCK", "BACKSLASH"}
local KeyOptions = {}
for i = 1, #Keys do KeyOptions[i] = { description = ""..Keys[i].."", data = "KEY_"..Keys[i] } end

local TF = {
	{ description = "true", data = true }, 
	{ description = "false", data = false },
}

server_filter_tags = {
	"interface",
	"tweak",
	"orangestaff",
	"blinkstaff",
	"telepoof",
	"reticule"
}

configuration_options = {
	{
		name = "enabled_key",
		label = "Turn on/off mod by",
		hover = "Set which key to switch the mod on/off",
		options = KeyOptions,
		default = "KEY_HOME",
	},
	{
		name = "orangestaff",
		label = "Enable for lazy explorer",
		hover = "Enable for lazy explorer",
		options = TF,
		default = true,
	},
	{
		name = "soulhop",
		label = "Enable for soul hop",
		hover = "Enable for soul hop on wortox",
		options = TF,
		default = true,
	}
}