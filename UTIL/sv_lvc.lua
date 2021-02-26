--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Last revision: FEBRUARY 25 2021 VERS. 3.2.1
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: server.lua
PURPOSE: Handle version checking, syncing sirens,
and opening links.
---------------------------------------------------
]]
--UPDATER
local repo_version
local updatePath = "/TrevorBarns/luxart-vehicle-control/releases/"

Citizen.CreateThread( function()
	resourceName = "Luxart Vehicle Control ("..GetCurrentResourceName()..")"
	PerformHttpRequest("https://raw.githubusercontent.com/TrevorBarns/luxart-vehicle-control/master/version", checkVersion, "GET")
end)

RegisterServerEvent("lvc_GetRepoVersion_s") 
AddEventHandler("lvc_GetRepoVersion_s", function()
    TriggerClientEvent("lvc_SendRepoVersion_c", source, repo_version)
end)

function checkVersion(err, responseText, headers)
	repo_version = responseText
    curVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    experimental = GetResourceMetadata(GetCurrentResourceName(), 'experimental', 0)
	if curVersion < repo_version then
		print("\n^1--------------------------------------------------------------------------------------------------------------------^7")
		print(resourceName.." is outdated, latest version is: ^2"..responseText.."^7, installed version: ^1"..curVersion.."^7!\nUpdate at https://github.com"..updatePath.."")
		print("^1--------------------------------------------------------------------------------------------------------------------^7\n")
	elseif curVersion > responseText and experimental ~= 'true' then
		print("\n^3--------------------------------------------------------------------------------------------------------------------^7")
		print(resourceName.." is on an experimental version: ^2"..responseText.."^7, installed version: ^1"..curVersion.."^7!\nYou may experience ^1bugs^7! Downgrade at https://github.com"..updatePath.."\n^2To suppress this message set convar 'experimental' to 'true'.^7")
		print("^3--------------------------------------------------------------------------------------------------------------------^7")
	end
end

RegisterServerEvent("lvc_TogDfltSrnMuted_s")
AddEventHandler("lvc_TogDfltSrnMuted_s", function(toggle)
	TriggerClientEvent("lvc_TogDfltSrnMuted_c", -1, source, toggle)
end)

RegisterServerEvent("lvc_SetLxSirenState_s")
AddEventHandler("lvc_SetLxSirenState_s", function(newstate)
	TriggerClientEvent("lvc_SetLxSirenState_c", -1, source, newstate)
end)

RegisterServerEvent("lvc_SetPwrcallState_s")
AddEventHandler("lvc_SetPwrcallState_s", function(newstate)
	TriggerClientEvent("lvc_SetPwrcallState_c", -1, source, newstate)
end)

RegisterServerEvent("lvc_SetAirManuState_s")
AddEventHandler("lvc_SetAirManuState_s", function(newstate)
	TriggerClientEvent("lvc_SetAirManuState_c", -1, source, newstate)
end)

RegisterServerEvent("lvc_TogIndicState_s")
AddEventHandler("lvc_TogIndicState_s", function(newstate)
	TriggerClientEvent("lvc_TogIndicState_c", -1, source, newstate)
end)

RegisterServerEvent("lvc_TogTkdState_s")
AddEventHandler("lvc_TogTkdState_s", function(newstate)
	TriggerClientEvent("lvc_TogTkdState_c", -1, source, newstate)
end)

--[[
RegisterServerEvent("lvc_ShareAudio_s")
AddEventHandler("lvc_ShareAudio_s", function(target, audiofile)
	TriggerClientEvent("lvc_ShareAudio_c", target, audiofile)
end)
]]
