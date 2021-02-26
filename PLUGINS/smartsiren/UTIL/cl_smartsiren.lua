--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Last revision: FEBRUARY 26 2021 (VERS. 3.2.1)
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_smartsiren.lua
PURPOSE: Contains threads, functions to 
automatically change siren tones based on vehicle
state / inputs.
---------------------------------------------------
]]

local SS = {}
local smart_siren_masterswitch = true
local smart_siren_timer = 2000
local horn_triggered_sirens = { 3, 4, 5 }
local saved_tone = nil
local active = false
local count = 0 
local timer = 2000
local pos = 1
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and smart_siren_masterswitch then
			if state_lxsiren[veh] ~= nil and state_airmanu[veh] ~= nil and ( state_lxsiren[veh] > 0 or actv_lxsrnmute_temp ) and state_airmanu[veh] > 0 then
					print(count)
					if count > 3 then
						count = 0
						if saved_tone == nil and state_lxsiren[veh] ~= 0 then
							saved_tone = state_lxsiren[veh]
						end
						if pos < #horn_triggered_sirens then
							pos = pos + 1
						end
						local new_tone = horn_triggered_sirens[pos]
						SetLxSirenStateForVeh(veh, new_tone)
						timer = 2000
						active = true
						Citizen.Wait(2000)
					end
				Citizen.Wait(1)
			end
		else
			Citizen.Wait(1000)
		end
		Citizen.Wait(0)
	end
end)


-- Activity Reminder Timer
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and smart_siren_masterswitch then
			if timer > 1 then
				Citizen.Wait(1000)
				timer = timer - 1000
			else
				count = 0
				pos = 1
				Citizen.Wait(100)
				if saved_tone ~= nil then
					SetLxSirenStateForVeh(veh, saved_tone)
					saved_tone = nil
				end
				timer = 2000
			end
		end
		Citizen.Wait(1000)
	end
end)


-- Activity Reminder Timer
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and not key_locked then
			if IsDisabledControlJustReleased(0, 86) then
				count = count + 1
			end
		end
		Citizen.Wait(0)
	end
end)
