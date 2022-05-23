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
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
---------------------------------------------------
]]
TRAIL = {}
TRAIL.custom_toggles_set = false

CreateThread(function()
	Wait(500)
	UTIL:FixOversizeKeys(TRAILERS)
end)

RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	if player_is_emerg_driver and veh ~= nil then
		TRAIL.TBL, profile = UTIL:GetProfileFromTable('TRAILERS', TRAILERS, veh, true)

		if not profile then
			TRAIL.custom_toggles_set = false
		else
			TRAIL.custom_toggles_set = true
		end
	end
end)

function TRAIL:GetTrailerDisplayName()
	if GetDisplayNameFromVehicleModel(GetEntityModel(trailer)) == 'CARNOTFOUND' then
		return Lang:t('plugins.ts_not_found')
	else
		return GetDisplayNameFromVehicleModel(GetEntityModel(trailer))
	end
end

function TRAIL:GetCabDisplayName()
	return GetDisplayNameFromVehicleModel(GetEntityModel(veh))
end

function TRAIL:SetExtraState(is_trailer, extra_id, state)
	if is_trailer then
		if DoesExtraExist(trailer, extra_id) then
			SetVehicleExtra(trailer, extra_id, not state)
		end
	else
		if DoesExtraExist(veh, extra_id) then
			SetVehicleExtra(veh, extra_id, not state)
		end
	end
end