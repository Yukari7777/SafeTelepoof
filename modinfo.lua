name = "Safe Telepoof"
version = "1.0.2"
description = "Stop wasting your lazy explorer's durability!\n\nWhile holding lazy explorer:\n- Right click + Left Click to telepoof\n- Right Click + Right Click to cancel"
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

server_filter_tags = {
	"interface",
	"tweak",
	"orangestaff",
	"blinkstaff",
	"telepoof",
	"reticule"
}

configuration_options = {
}