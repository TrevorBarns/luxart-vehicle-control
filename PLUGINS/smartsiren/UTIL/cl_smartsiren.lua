--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
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
local horn_triggered_sirens = { 3, 4, 5 }
local saved_tone = nil
local active = false
local count = 0 
local hold_to_count = 0 
local hold_to_count_max = 55
local ss_run_timer_default = smart_siren_runtime * 1000
local ss_run_timer = ss_run_timer_default

local count_reset_timer_default = trigger_reset_timer * 1000
local count_reset_timer = count_reset_timer_default

local count_trigger_val = trigger_count
local pos = 1
local new_tone

Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and smart_siren_masterswitch then
			if state_lxsiren[veh] ~= nil and state_airmanu[veh] ~= nil then
				-- SIREN IS ON OR IS OFF BY BEING ACTIVELY INTERRUPTED
				if ( state_lxsiren[veh] > 0 or actv_lxsrnmute_temp ) and state_airmanu[veh] > 0 then
					if count > count_trigger_val and not active then
						--	GET THE TONE TO SAVE
						--	IF INTERRUPTED, THEN GET TONE ID FROM CL_LVC SINCE STATE_LXSIREN[VEH] = 0
						if actv_lxsrnmute_temp then
							saved_tone = srntone_temp
							actv_lxsrnmute_temp = false
						else
							saved_tone = state_lxsiren[veh]
						end
						
						--	GET SMART SIREN TONE ID
						pos = math.random(1, #horn_triggered_sirens)
						new_tone = horn_triggered_sirens[pos]
						
						SetLxSirenStateForVeh(veh, new_tone)
						active = true
						ss_run_timer = 4000
						Citizen.Wait(2000)
					end
				end
				Citizen.Wait(1)
			end
		else
			Citizen.Wait(1000)
		end
		Citizen.Wait(0)
	end
end)


-- Smart Siren Run Timer
--	How long SS should run after being activated.
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and smart_siren_masterswitch then
			if state_lxsiren[veh] ~= nil and state_airmanu[veh] ~= nil then
				-- SIREN IS ON OR IS OFF BY BEING ACTIVELY INTERRUPTED
				if ( state_lxsiren[veh] > 0 or actv_lxsrnmute_temp ) then
					if IsDisabledControlReleased(0, 86) then
						if ss_run_timer > 1 then
							Citizen.Wait(500)
							ss_run_timer = ss_run_timer - 500
						else
							RunTimerFinished()
							ss_run_timer = ss_run_timer_default
						end
					else
						ss_run_timer = ss_run_timer_default
					end
				end
			end
		else
			Citizen.Wait(500)
		end
		Citizen.Wait(0)
	end
end)

function RunTimerFinished()
	if saved_tone ~= nil then
		if ( state_lxsiren[veh] > 0 or actv_lxsrnmute_temp ) then
			SetLxSirenStateForVeh(veh, saved_tone)
		end
		saved_tone = nil
		active = false
	end
end

-- Trigger Reset Timer
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and smart_siren_masterswitch then
			if state_lxsiren[veh] ~= nil and state_airmanu[veh] ~= nil then
				-- SIREN IS ON OR IS OFF BY BEING ACTIVELY INTERRUPTED
				if ( state_lxsiren[veh] > 0 or actv_lxsrnmute_temp ) and state_airmanu[veh] > 0 then
					if IsDisabledControlReleased(0, 86) then
						if count_reset_timer > 1 then
							Citizen.Wait(500)
							count_reset_timer = count_reset_timer - 500
						else
							CountTimerFinished()
							count_reset_timer = count_reset_timer_default
						end
					end
				else
					Citizen.Wait(1000)
				end
			else
				Citizen.Wait(500)
			end
		end
		Citizen.Wait(0)
	end
end)

function CountTimerFinished()
	count = 0
end


-- Trigger Counter for Tap
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and not key_locked then
			if IsDisabledControlJustReleased(0, 86) and not active then
				count = count + 1
			end
		end
		Citizen.Wait(0)
	end
end)


-- Trigger Counter for Hold
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and not key_locked then
			if IsDisabledControlPressed(0, 86) and not active then
				while IsDisabledControlPressed(0, 86) do
					Citizen.Wait(1)
					if not active then
						if hold_to_count < hold_to_count_max then
							hold_to_count = hold_to_count + 1
						else
							count = count_trigger_val + 1
							hold_to_count = 0
						end
					end
				end
				hold_to_count = 0
			end
		end
		Citizen.Wait(0)
	end
end)


-- Trigger Counter for Hold
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and not key_locked and smart_siren_masterswitch then	
			HUD:ShowText(0.5, 0.8, 1, ss_run_timer, 0.5)
		end
		Citizen.Wait(0)
	end
end)