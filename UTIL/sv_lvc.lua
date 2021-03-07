--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: server.lua
PURPOSE: Handle version checking, syncing vehicle 
states.
---------------------------------------------------
]]

---------------VEHICLE STATE EVENTS----------------
RegisterServerEvent("lvc_GetRepoVersion_s") 
AddEventHandler("lvc_GetRepoVersion_s", function()
    TriggerClientEvent("lvc_SendRepoVersion_c", source, repo_version)
end)

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

-------------VERSION CHECKING & STARTUP------------
local curr_version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
local repo_version	-- LVC repo version
local experimental = GetResourceMetadata(GetCurrentResourceName(), 'experimental', 0) == 'true' 

local plugin_count = 0
local plugins_cv = { }		-- table of active plugins current versions plugins_cv = { ['<pluginname>'] = <version> }
local plugins_rv = { }		-- table of active plugins repository versions


--	PLUGIN VERSION CHECKING EVENT	
RegisterServerEvent("lvc:plugins_storePluginVersion") 
AddEventHandler("lvc:plugins_storePluginVersion", function(name, version)
	plugin_count = plugin_count + 1
	plugins_cv[name] = version
end)


Citizen.CreateThread( function()
-- Get LVC repo version from github
	PerformHttpRequest("https://raw.githubusercontent.com/TrevorBarns/luxart-vehicle-control/master/version", function(err, responseText, headers)
		if responseText ~= nil and responseText ~= "" then
			repo_version = responseText
		end
	end)
	
	Citizen.Wait(1000)
  -- Get currently installed & enabled plugin versions (plugins -> 'lvc:plugins_storePluginVersion')
	TriggerEvent('lvc:plugins_getVersions')
	
  -- Get repo version for installed & enabled plugins
	for name, _ in pairs(plugins_cv) do
		PerformHttpRequest("https://raw.githubusercontent.com/TrevorBarns/luxart-vehicle-control/master/PLUGINS/"..name.."/version", function(err, responseText, headers)
			if responseText ~= nil and responseText ~= "" then
				plugins_rv[name] = responseText
			else
				plugins_rv[name] = "unkn"
			end
		end)
	end
	Citizen.Wait(1000)
	print("\n\t^7 ________________________________________________________")   
	print("\t|\t^8      __                       ^9___               ^7|")   
	print("\t|\t^8     / /      ^7 /\\   /\\        ^9/ __\\              ^7|")   
	print("\t|\t^8    / /        ^7\\ \\ / /       ^9/ /                 ^7|")   
	print("\t|\t^8   / /___       ^7\\ V /       ^9/ /___               ^7|")   
	print("\t|\t^8   \\____/uxart   ^7\\_/ ehicle ^9\\____/ontrol         ^7|")   
	print("\t|\t                                                 |")   
	print("\t|\t         INSTALLED VERSION: "..curr_version.."                |")   
	print("\t|\t           LATEST VERSION:  "..repo_version.."                |") 
	--	UPDATE DETECTED
	if curr_version < repo_version then
		print("\t|\t             ^8UPDATE REQUIRED                     ^7|")
		print("\t|^8                      DOWNLOAD AT:                      ^7|")
		print("\t|^2 github.com/TrevorBarns/luxart-vehicle-control/releases ^7|")
	--	EXPERMENTAL VERSION 
	elseif curr_version  > repo_version then
		print("\t|\t           ^3EXPERIMENTAL VERSION                  ^7|")
		-- IS THE USER AWARE THEY DOWNLOADED EXPERMENTAL CHECK CONVARS
		if experimental == 'false' then
		print("\t|^3 THIS VERSION IS IN DEVELOPMENT AND IS NOT RECOMMENDED  ^7|")
		print("\t|^3 FOR PRODUCTION USE. IF THIS WAS A MISTAKE DOWNLOAD THE ^7|")
		print("\t|^3 LATEST STABLE RELEASE AT:                              ^7|")
		print("\t|^2 github.com/TrevorBarns/luxart-vehicle-control/releases ^7|")
		print("\t|^3 TO MUTE THIS: SET CONVAR 'experimental' to 'true'      ^7|")
		end
	end
	
	--	IF PLUGINS ARE INSTALLED 
	if plugin_count > 0 then
		print("\t^7|________________________________________________________|") 			
		print("\t^7|INSTALLED PLUGINS               | INSTALLED |  LATEST   |") 			
		for name, version in pairs(plugins_cv) do
			local plugin_string
			if plugins_cv[name] < plugins_rv[name] then
				plugin_string = string.format("\t|^8  %-30s^7|^8   %s   ^7|^8   %s   ^7|^8 UPDATE REQUIRED    ^7", name, plugins_cv[name], plugins_rv[name])					
			elseif plugins_cv[name] > plugins_rv[name] then
				plugin_string = string.format("\t|^3  %-30s^7|^3   %s   ^7|^3   %s   ^7|^3 EXPERIMENTAL VERSION ^7", name, plugins_cv[name], plugins_rv[name])					
			else
				plugin_string = string.format("\t|  %-30s|   %s   |   %s   |", name, plugins_cv[name], plugins_rv[name])
			end
			print(plugin_string)
		end
		print("\t^7|________________________________________________________|") 
		print("\t^7|      Updates, Support, Feedback: ^5discord.link/LVC      ^7|")   
		print("\t^7|________________________________________________________|\n\n") 
	else
		print("\t^7|________________________________________________________|") 
		print("\t^7|      Updates, Support, Feedback: ^5discord.link/LVC      ^7|")   
		print("\t^7|________________________________________________________|\n\n")   
	end
end)