--[[
---------------------------------------------------
LUXART VEHICLE CONTROL (FOR FIVEM)
---------------------------------------------------
Last revision: DECEMBER 26 2020 (VERS. 3.1.6)
Coded by Lt.Caine
ELS Clicks by Faction
Additonal Modification by TrevorBarns
---------------------------------------------------
FILE: server.lua
PURPOSE: Handle version checking, syncing sirens,
and opening links.
---------------------------------------------------
]]
--UPDATER
local repo_version

Citizen.CreateThread( function()
	updatePath = "/TrevorBarns/luxart-vehicle-control"
	resourceName = "Luxart Vehicle Control ("..GetCurrentResourceName()..")"
	PerformHttpRequest("https://raw.githubusercontent.com"..updatePath.."/master/version", checkVersion, "GET")
end)

RegisterServerEvent("lvc_GetVersion_s") 
AddEventHandler("lvc_GetVersion_s", function()
    TriggerClientEvent("lvc_GetVersion_c", -1, source, repo_version)
end)

RegisterServerEvent('lvc_OpenLink_s')
AddEventHandler('lvc_OpenLink_s', function(link)
    os.execute("start " .. link)
end)


function checkVersion(err,responseText, headers)
	repo_version = responseText
    curVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
	if curVersion < responseText then
		print("\n^1----------------------------------------------------------------------------------^7")
		print(resourceName.." is outdated, latest version is: ^2"..responseText.."^7, installed version: ^1"..curVersion.."^7!\nupdate from https://github.com"..updatePath.."")
		print("^1----------------------------------------------------------------------------------^7\n")
	elseif curVersion > responseText then
		--print("\n^3----------------------------------------------------------------------------------^7")
		--print(resourceName.." git version is: ^2"..responseText.."^7, installed version: ^1"..curVersion.."^7!")
		--print("^3----------------------------------------------------------------------------------^7")
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

RegisterServerEvent("lvc_TogPwrcallState_s")
AddEventHandler("lvc_TogPwrcallState_s", function(newstate)
	TriggerClientEvent("lvc_TogPwrcallState_c", -1, source, newstate)
end)

RegisterServerEvent("lvc_SetAirManuState_s")
AddEventHandler("lvc_SetAirManuState_s", function(newstate)
	TriggerClientEvent("lvc_SetAirManuState_c", -1, source, newstate)
end)

RegisterServerEvent("lvc_TogIndicState_s")
AddEventHandler("lvc_TogIndicState_s", function(newstate)
	TriggerClientEvent("lvc_TogIndicState_c", -1, source, newstate)
end)

