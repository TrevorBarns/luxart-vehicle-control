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

local curr_version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
local experimental = GetResourceMetadata(GetCurrentResourceName(), 'experimental', 0) == 'true' 

local plugin_count = 0
local plugins_cv = { }		-- table of active plugins current versions plugins_cv = { ['<pluginname>'] = <version> }
local plugins_rv = { }		-- table of active plugins repository versions

---------------VEHICLE STATE EVENTS----------------
RegisterServerEvent('lvc:GetRepoVersion_s') 
AddEventHandler('lvc:GetRepoVersion_s', function()
	TriggerClientEvent('lvc:SendRepoVersion_c', source, repo_version)
end)

RegisterServerEvent('lvc:TogDfltSrnMuted_s')
AddEventHandler('lvc:TogDfltSrnMuted_s', function(toggle)
	TriggerClientEvent('lvc:TogDfltSrnMuted_c', -1, source, toggle)
end)

RegisterServerEvent('lvc:SetLxSirenState_s')
AddEventHandler('lvc:SetLxSirenState_s', function(newstate)
	TriggerClientEvent('lvc:SetLxSirenState_c', -1, source, newstate)
end)

RegisterServerEvent('lvc:SetPwrcallState_s')
AddEventHandler('lvc:SetPwrcallState_s', function(newstate)
	TriggerClientEvent('lvc:SetPwrcallState_c', -1, source, newstate)
end)

RegisterServerEvent('lvc:SetAirManuState_s')
AddEventHandler('lvc:SetAirManuState_s', function(newstate)
	TriggerClientEvent('lvc:SetAirManuState_c', -1, source, newstate)
end)

RegisterServerEvent('lvc:TogIndicState_s')
AddEventHandler('lvc:TogIndicState_s', function(newstate)
	TriggerClientEvent('lvc:TogIndicState_c', -1, source, newstate)
end)

-------------VERSION CHECKING & STARTUP------------
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
  -- Get currently installed plugin versions (plugins -> 'lvc:plugins_storePluginVersion')
	TriggerEvent('lvc:plugins_getVersions')
	
  -- Get repo version for installed plugins
	for name, _ in pairs(plugins_cv) do
		PerformHttpRequest("https://raw.githubusercontent.com/TrevorBarns/luxart-vehicle-control/master/PLUGINS/"..name.."/version", function(err, responseText, headers)
			if responseText ~= nil and responseText ~= "" then
				plugins_rv[name] = responseText
			else
				plugins_rv[name] = "UNKWN"
			end
		end)
	end
	
	if GetCurrentResourceName() == 'lvc' then
		if community_id ~= nil and community_id ~= '' then
			Citizen.Wait(1000)
			print("\n\t^7 ________________________________________________________")   
			print("\t|\t^8      __                       ^9___               ^7|")   
			print("\t|\t^8     / /      ^7 /\\   /\\        ^9/ __\\              ^7|")   
			print("\t|\t^8    / /        ^7\\ \\ / /       ^9/ /                 ^7|")   
			print("\t|\t^8   / /___       ^7\\ V /       ^9/ /___               ^7|")   
			print("\t|\t^8   \\____/uxart   ^7\\_/ ehicle ^9\\____/ontrol         ^7|")   
			print("\t|\t                                                 |")   
			print(string.format("\t|\t            COMMUNITY ID: %-23s|", community_id))
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
				if not experimental then
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
					if plugins_rv[name] ~= "UNKWN" and plugins_cv[name] < plugins_rv[name]  then
						plugin_string = string.format("\t|^8  %-30s^7|^8   %s   ^7|^8   %s   ^7|^8 UPDATE REQUIRED    ^7", name, plugins_cv[name], plugins_rv[name])					
					elseif plugins_cv[name] > plugins_rv[name] or plugins_rv[name] == "UNKWN" then
						plugin_string = string.format("\t|^3  %-30s^7|^3   %s   ^7|^3   %s   ^7|^3 EXPERIMENTAL VERSION ^7", name, plugins_cv[name], plugins_rv[name])					
					else
						plugin_string = string.format("\t|  %-30s|   %s   |   %s   |", name, plugins_cv[name], plugins_rv[name])
					end
					print(plugin_string)
				end
				print("\t^7|________________________________________________________|") 
				print("\t^7|      Updates, Support, Feedback: ^5discord.link/LVC      ^7|")   
				print("\t^7|________________________________________________________|\n\n")   
			end
		else
			print("\n\t^7 ________________________________________________________")   
			print("\t|\t^8      __                       ^9___               ^7|")   
			print("\t|\t^8     / /      ^7 /\\   /\\        ^9/ __\\              ^7|")   
			print("\t|\t^8    / /        ^7\\ \\ / /       ^9/ /                 ^7|")   
			print("\t|\t^8   / /___       ^7\\ V /       ^9/ /___               ^7|")   
			print("\t|\t^8   \\____/uxart   ^7\\_/ ehicle ^9\\____/ontrol         ^7|")  
			print("\t|\t                                                 |")   
			print("\t|\t         INSTALLED VERSION: "..curr_version.."                |")   
			print("\t|\t           LATEST VERSION:  "..repo_version.."                |") 		
			print("\t|\t^8             CONFIGURATION ERROR                 ^7|")
			print("\t|^8 COMMUNITY ID MISSING, THIS IS REQUIRED TO PREVENT      ^7|")
			print("\t|^8 CONFLICTS FOR PLAYERS WHO PLAY ON MULTIPLE SERVERS     ^7|")
			print("\t|^8 WITH LVC. PLEASE SET THIS IN SETTINGS.LUA.             ^7|")
			print("\t^7|________________________________________________________|") 
			print("\t^7|      Updates, Support, Feedback: ^5discord.link/LVC      ^7|")   
			print("\t^7|________________________________________________________|\n\n") 
		end
	else
			print("\n\t^7 ________________________________________________________")   
			print("\t|\t^8      __                       ^9___               ^7|")   
			print("\t|\t^8     / /      ^7 /\\   /\\        ^9/ __\\              ^7|")   
			print("\t|\t^8    / /        ^7\\ \\ / /       ^9/ /                 ^7|")   
			print("\t|\t^8   / /___       ^7\\ V /       ^9/ /___               ^7|")   
			print("\t|\t^8   \\____/uxart   ^7\\_/ ehicle ^9\\____/ontrol         ^7|")  
			print("\t|\t                                                 |")   
			print("\t|\t         INSTALLED VERSION: "..curr_version.."                |")   
			print("\t|\t           LATEST VERSION:  "..repo_version.."                |") 		
			print("\t|\t^8             CONFIGURATION ERROR                 ^7|")
			print("\t|^8 INVALID RESOURCE NAME. PLEASE VERIFY RESOURCE FOLDER   ^7|")
			print("\t|^8 NAME READS '^3lvc^8' (CASE-SENSITIVE). THIS IS REQUIRED    ^7|")
			print("\t|^8 FOR PROPER SAVE / LOAD FUNCTIONALITY. PLEASE RENAME,   ^7|")
			print("\t|^8 REFRESH, AND ENSURE.                                   ^7|")
			print("\t^7|________________________________________________________|") 
			print("\t^7|      Updates, Support, Feedback: ^5discord.link/LVC      ^7|")   
			print("\t^7|________________________________________________________|\n\n") 
	end
end)