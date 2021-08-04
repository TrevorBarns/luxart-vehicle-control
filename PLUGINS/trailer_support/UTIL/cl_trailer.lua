--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
Traffic Advisor Plugin by Dawson
---------------------------------------------------
FILE: cl_trailer.lua
PURPOSE: Contains threads, functions for trailer 
support.
---------------------------------------------------
]]
TRAIL = {}
TRAIL.custom_toggles_set = false

Citizen.CreateThread(function()
	Citizen.Wait(500)
	UTIL:FixOversizeKeys(TRAILERS)
end) 

RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	if player_is_emerg_driver and veh ~= nil then
		local veh_name_wildcard = string.gsub(TRAIL:GetCabDisplayName(), "%d+", "#")

		if TRAILERS[TRAIL:GetCabDisplayName()] ~= nil or TRAILERS[veh_name_wildcard] ~= nil then
			TRAIL.custom_toggles_set = true
		else
			TRAIL.custom_toggles_set = false
		end
	end
end)

function TRAIL:GetTrailerDisplayName()
	if GetDisplayNameFromVehicleModel(GetEntityModel(trailer)) == "CARNOTFOUND" then
		return "NOT FOUND"
	else
		return GetDisplayNameFromVehicleModel(GetEntityModel(trailer))
	end
end

function TRAIL:GetCabDisplayName()
	return GetDisplayNameFromVehicleModel(GetEntityModel(veh))
end

function TRAIL:SetExtraState(trailer, extra_id, state)
	if trailer then
		if DoesExtraExist(trailer, extra_id) then
			SetVehicleExtra(trailer, extra_id, not state)
		end
	else 
		if DoesExtraExist(veh, extra_id) then
			SetVehicleExtra(veh, extra_id, not state)
		end
	end
end