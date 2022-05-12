--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_audio.lua
PURPOSE: NUI Audio Related Functions.
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
AUDIO = { }
local activity_timer 			= 0
local activity_reminder_index	= 1
local activity_reminder_lookup = { [2] = 30000, [3] = 60000, [4] = 120000, [5] = 300000, [6] = 600000 }

AUDIO.radio_masterswitch 		= true
AUDIO.airhorn_button_SFX 		= false
AUDIO.manu_button_SFX 			= false

AUDIO.button_sfx_scheme_choices	= button_sfx_scheme_choices
AUDIO.button_sfx_scheme			= default_sfx_scheme_name
AUDIO.on_volume					= default_on_volume
AUDIO.off_volume				= default_off_volume
AUDIO.upgrade_volume 			= default_upgrade_volume
AUDIO.downgrade_volume 			= default_downgrade_volume
AUDIO.hazards_volume 			= default_hazards_volume
AUDIO.lock_volume 				= default_lock_volume
AUDIO.lock_reminder_volume		= default_lock_reminder_volume
AUDIO.activity_reminder_volume 	= default_reminder_volume

------ACTIVITY REMINDER FUNCTIONALITY------
CreateThread(function()
	while true do
		while activity_reminder_index > 1 and player_is_emerg_driver do
			if IsVehicleSirenOn(veh) and state_lxsiren[veh] == 0 and state_pwrcall[veh] == 0 then
				if activity_timer < 1 then
					AUDIO:Play('Reminder', AUDIO.activity_reminder_volume)
					AUDIO:ResetActivityTimer()
				end
			end
			Wait(100)
		end
		Wait(1000)
	end
end)

-- Activity Reminder Timer
CreateThread(function()
	while true do
		if veh ~= nil then
			while activity_reminder_index > 1 and IsVehicleSirenOn(veh) and state_lxsiren[veh] == 0 and state_pwrcall[veh] == 0 do
				if activity_timer > 1 then
					Wait(1000)
					activity_timer = activity_timer - 1000
				else
					Wait(100)
					AUDIO:ResetActivityTimer()
				end
			end
		end
		Wait(1000)
	end
end)

---------------------------------------------------------------------
--[[Play NUI front in audio.]]
function AUDIO:Play(soundFile, soundVolume, schemeless)
	local schemeless = schemeless or false
	if not schemeless then
		soundFile = AUDIO.button_sfx_scheme .. '/' .. soundFile;
	end

	SendNUIMessage({
	  _type  = 'audio',
	  file   = soundFile,
	  volume = soundVolume
	})
end

--[[After activity has occurred, reset the activity timer to the selected reminder interval]]
function AUDIO:ResetActivityTimer()
	activity_timer = activity_reminder_lookup[activity_reminder_index] or 0
end

--[[Getter for current time in seconds remaining.]]
function AUDIO:GetActivityTimer()
	return activity_timer
end

--[[After activity has occurred, reset the activity timer to the selected reminder interval]]
function AUDIO:GetActivityReminderIndex()
	return activity_reminder_index
end

--[[Setter for activity reminder index]]
function AUDIO:SetActivityReminderIndex(index)
	if index ~= nil then
		activity_reminder_index = index
	end
end
