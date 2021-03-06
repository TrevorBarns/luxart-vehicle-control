--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: sv_version.lua
PURPOSE: Handle plugin version checking.
---------------------------------------------------
]]

local plugin_name = "smartsiren"
local plugin_version = "0.8.0"

RegisterServerEvent("lvc:plugins_getVersions") 
AddEventHandler("lvc:plugins_getVersions", function()
	TriggerEvent("lvc:plugins_storePluginVersion", plugin_name, plugin_version)
end)