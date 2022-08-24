--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_utils.lua
PURPOSE: Utilities for siren assignments and tables
		 and other common functions.
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
UTIL = { }

local approved_tones = nil
local tone_options = { }
local tone_table_names_ids = { }
local profile = nil
local tone_main_mem_id = nil
local tone_PMANU_id = nil
local tone_SMANU_id = nil
local tone_AUX_id = nil
local tone_ARHRN_id = nil

---------------------------------------------------------------------
--[[Return sub-table for sirens or plugin settings tables, given veh, and name of whatever setting.]]
function UTIL:GetProfileFromTable(print_name, tbl, veh, ignore_missing_default)
	local ignore_missing_default = ignore_missing_default or false
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local lead_and_trail_wildcard = veh_name:gsub('%d+', '#')
	local lead = veh_name:match('%d*%a+')
	local trail = veh_name:gsub(lead, ''):gsub('%d+', '#')
	local trail_only_wildcard = string.format('%s%s', lead, trail)

	local profile_table, profile
	if tbl ~= nil then
		if tbl[veh_name] ~= nil then							--Does profile exist as outlined in vehicle.meta
			profile_table = tbl[veh_name]
			profile = veh_name
			UTIL:Print(Lang:t('info.profile_found', {ver = STORAGE:GetCurrentVersion(), tbl = print_name, profile = profile, model = veh_name}))
		elseif tbl[trail_only_wildcard] ~= nil then				--Does profile exist using # as wildcard for any trailing digits.
			profile_table = tbl[trail_only_wildcard]
			profile = trail_only_wildcard
			UTIL:Print(Lang:t('info.profile_found', {ver = STORAGE:GetCurrentVersion(), tbl = print_name, profile = profile, model = veh_name}))
		elseif tbl[lead_and_trail_wildcard] ~= nil then			--Does profile exist using # as wildcard for any digits.
			profile_table = tbl[lead_and_trail_wildcard]
			profile = lead_and_trail_wildcard
			UTIL:Print(Lang:t('info.profile_found', {ver = STORAGE:GetCurrentVersion(), tbl = print_name, profile = profile, model = veh_name}))
		else
			if tbl['DEFAULT'] ~= nil then
				profile_table = tbl['DEFAULT']
				profile = 'DEFAULT'
				UTIL:Print(Lang:t('info.profile_default_console', {ver = STORAGE:GetCurrentVersion(), tbl = print_name, model = veh_name}))
				if print_name == 'SIRENS' then
					HUD:ShowNotification(Lang:t('info.profile_default_frontend', {model = veh_name}))
				end
			else
				profile_table = { }
				profile = false
				if not ignore_missing_default then
					UTIL:Print(Lang:t('warning.profile_missing', {ver = STORAGE:GetCurrentVersion(), tbl = print_name, model = veh_name}), true)
				end
			end
		end
	else
		profile_table = { }
		profile = false
		HUD:ShowNotification(Lang:t('error.profile_nil_table', {tbl = print_name}), true)
		UTIL:Print(Lang:t('error.profile_nil_table_console', {ver = STORAGE:GetCurrentVersion(), tbl = print_name}), true)
	end
	
	return profile_table, profile
end

---------------------------------------------------------------------
--[[Shorten oversized <gameName> strings in SIREN_ASSIGNMENTS (SIRENS.LUA).
    GTA only allows 11 characters. So to reduce confusion we'll shorten it if the user does not.]]
function UTIL:FixOversizeKeys(TABLE)
	for i, tbl in pairs(TABLE) do
		if string.len(i) > 11 then
			local shortened_gameName = string.sub(i,1,11)
			TABLE[shortened_gameName] = TABLE[i]
			TABLE[i] = nil
		end
	end
end

---------------------------------------------------------------------
--[[Sets profile name and approved_tones table a copy of SIREN_ASSIGNMENTS for this vehicle]]
function UTIL:UpdateApprovedTones(veh)
	approved_tones, profile = UTIL:GetProfileFromTable('SIRENS', SIREN_ASSIGNMENTS, veh)
	
	if profile == false then
		UTIL:Print(Lang:t('error.profile_none_found_console', {game_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))}), true)
		HUD:ShowNotification(Lang:t('error.profile_none_found_frontend'), true)
	end

	if profile then
		if not UTIL:IsApprovedTone('MAIN_MEM') then
			UTIL:SetToneByPos('MAIN_MEM', 2)
		end
		if not UTIL:IsApprovedTone('PMANU') then
			UTIL:SetToneByPos('PMANU', 2)
		end
		if not UTIL:IsApprovedTone('SMANU') then
			UTIL:SetToneByPos('SMANU', 3)
		end
		if not UTIL:IsApprovedTone('AUX') then
			UTIL:SetToneByPos('AUX', 2)
		end
		if not UTIL:IsApprovedTone('ARHRN') then
			UTIL:SetToneByPos('ARHRN', 1)
		end
	end
end

--[[Getter for approved_tones table, used in RageUI]]
function UTIL:GetApprovedTonesTable()
	if approved_tones == nil then
		if veh ~= nil then
			UpdateApprovedTones(veh)
		else
			UpdateApprovedTones('DEFAULT')
		end
	end
	return approved_tones
end
---------------------------------------------------------------------
--[[Builds a table that we store tone_options in (disabled, button & cycle, cycle only, button only).
    Users can set default option of siren by using optional index .Option in SIREN_ASSIGNMENTS table in SIRENS.LUA]]
function UTIL:BuildToneOptions()
	local temp_array = { }
	local option
	for i, id in pairs(approved_tones) do
		if SIRENS[id] ~= nil then
			option = SIRENS[id].Option or 1
			temp_array[id] = option
		end
	end
	tone_options = temp_array
end

--Setter for single tone_option
function UTIL:SetToneOption(tone_id, option)
	tone_options[tone_id] = option
end

--Getter for single tone_option
function UTIL:GetToneOption(tone_id)
	return tone_options[tone_id]
end

--Getter for tone_options table (used for saving)
function UTIL:GetToneOptionsTable()
	return tone_options
end
---------------------------------------------------------------------
--[[RageUI requires a specific table layout, this builds it according to SIREN_ASSIGNMENTS > approved_tones.]]
function UTIL:GetApprovedTonesTableNameAndID()
	local temp_array = { }
	for i, tone_id in pairs(approved_tones) do
		if i ~= 1 then
			table.insert(temp_array, { Name = SIRENS[tone_id].Name, Value = tone_id } )
		end
	end
	return temp_array
end

---------------------------------------------------------------------
--[[Getter for tone id by passing string abbreviation (MAIN_MEM, PMANU, etc.)]]
function UTIL:GetToneID(tone_string)
	if tone_string == 'MAIN_MEM' then
		return tone_main_mem_id
	elseif tone_string == 'PMANU' then
		return tone_PMANU_id
	elseif tone_string == 'SMANU' then
		return tone_SMANU_id
	elseif tone_string == 'AUX' then
		return tone_AUX_id
	elseif tone_string == 'ARHRN' then
		return tone_ARHRN_id
	end
end

--[[Setter for ToneID by passing string abbreviation of tone (MAIN_MEM, PMANU, etc.) and position of desired tone in approved_tones.]]
function UTIL:SetToneByPos(tone_string, pos)
	if profile then
		if approved_tones[pos] ~= nil then
			if tone_string == 'MAIN_MEM' then
				tone_main_mem_id = approved_tones[pos]
			elseif tone_string == 'PMANU' then
				tone_PMANU_id = approved_tones[pos]
			elseif tone_string == 'SMANU' then
				tone_SMANU_id = approved_tones[pos]
			elseif tone_string == 'AUX' then
				tone_AUX_id = approved_tones[pos]
			elseif tone_string == 'ARHRN' then
				tone_ARHRN_id = approved_tones[pos]
			end
		else
			HUD:ShowNotification(Lang:t('warning.too_few_tone_frontend', {code = 403}), false)
			UTIL:Print(Lang:t('warning.too_few_tone_console', {ver = STORAGE:GetCurrentVersion(), code = 403, tone_string = tone_string, pos = pos}), true)
		end
	else
		HUD:ShowNotification(Lang:t('warning.tone_position_nil_frontend', {code = 404}), false)
		UTIL:Print(Lang:t('warning.tone_position_nil_console', {ver = STORAGE:GetCurrentVersion(), code = 404, tone_string = tone_string, pos = pos}), true)
	end
end

--[[Getter for position of passed tone string. Used in RageUI for P/S MANU and AUX Siren.]]
function UTIL:GetTonePos(tone_string)
	local current_id = UTIL:GetToneID(tone_string)
	for i, tone_id in pairs(approved_tones) do
		if tone_id == current_id then
			return i
		end
	end
	return -1
end

--[[Getter for Tone ID at index/pos in approved_tones]]
function UTIL:GetToneAtPos(pos)
	if approved_tones[pos] ~= nil then
		return approved_tones[pos]
	end
	return nil
end


--[[Setter for ToneID by passing string abbreviation of tone (MAIN_MEM, PMANU, etc.) and specific ID.]]
function UTIL:SetToneByID(tone_string, tone_id)
	if UTIL:IsApprovedTone(tone_id) then
		if tone_string == 'MAIN_MEM' then
			tone_main_mem_id = tone_id
		elseif tone_string == 'PMANU' then
			tone_PMANU_id = tone_id
		elseif tone_string == 'SMANU' then
			tone_SMANU_id = tone_id
		elseif tone_string == 'AUX' then
			tone_AUX_id = tone_id
		elseif tone_string == 'ARHRN' then
			tone_ARHRN_id = tone_id
		end
	else
		HUD:ShowNotification(Lang:t('warning.tone_id_nil_frontend', {ver = STORAGE:GetCurrentVersion()}), false)
		UTIL:Print(Lang:t('warning.tone_id_nil_console', {ver = STORAGE:GetCurrentVersion(), tone_string = tone_string, tone_id = tone_id}), true)
	end
end

---------------------------------------------------------------------
--[[Gets next tone based off vehicle profile and current tone.]]
function UTIL:GetNextSirenTone(current_tone, veh, main_tone, last_pos)
	local main_tone = main_tone or false
	local last_pos = last_pos or nil
	local result

	if last_pos == nil then
		for i, tone_id in pairs(approved_tones) do
			if tone_id == current_tone then
				temp_pos = i
				break
			end
		end
	else
		temp_pos = last_pos
	end

	if temp_pos < #approved_tones then
		temp_pos = temp_pos+1
		result = approved_tones[temp_pos]
	else
		temp_pos = 2
		result = approved_tones[2]
	end

	if main_tone then
		--Check if the tone is set to 'disable' or 'button-only' if so, find next tone
		if tone_options[result] > 2 then
			result = UTIL:GetNextSirenTone(result, veh, main_tone, temp_pos)
		end
	end

	return result
end

---------------------------------------------------------------------
--[[Get count of approved tones used when mapping RegisteredKeys]]
function UTIL:GetToneCount()
	return #approved_tones
end

---------------------------------------------------------------------
--[[Ensure not all sirens are disabled / button only]]
function UTIL:IsOkayToDisable()
	local count = 0
	for i, option in pairs(tone_options) do
		if i ~= 1 then
			if option < 3 then
				count = count + 1
			end
		end
	end
	if count > 1 then
		return true
	end
	return false
end

------------------------------------------------
--[[Handle changing of tone_table custom names]]
function UTIL:ChangeToneString(tone_id, new_name)
	STORAGE:SetCustomToneStrings(true)
	SIRENS[tone_id].Name = new_name
end

------------------------------------------------
--[[Used to verify tone is allowed before playing.]]
function UTIL:IsApprovedTone(tone)
	for i, approved_tone in ipairs(approved_tones) do
		if approved_tone == tone then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
--[[Returns String <gameName> used for saving, loading, and debugging]]
function UTIL:GetVehicleProfileName()
	return profile
end

---------------------------------------------------------------------
--[[Prints to FiveM console, prints more when debug flag is enabled or overridden for important information]]
function UTIL:Print(string, override)
	override = override or false
	if debug_mode or override then
		print(string)
	end
end

---------------------------------------------------------------------
--[[Finds index of element in table given table and element.]]
function UTIL:IndexOf(tbl, tgt)
	for i, v in pairs(tbl) do
		if v == tgt then
			return i
		end
	end
	return nil
end

---------------------------------------------------------------------
--[[This function looks like #!*& for user convenience (and my lack of skill or abundance of laziness),
	it is called when needing to change an extra, it allows users to do things like ['<model>'] = { Brake = 1 } while
	also allowing advanced users to write configs like this ['<model>'] = { Brake = { add = { 3, 4 }, remove = { 5, 6 }, repair = true } }
	which can add and remove multiple different extras at once and adds flag to repair the vehicle
	for extras that are too large and require the vehicle to be reloaded. Once it figures out the
	users config layout it calls itself again (recursive) with the id we actually need toggled right now.]]
function UTIL:TogVehicleExtras(veh, extra_id, state, repair)
	local repair = repair or false
	if type(extra_id) == 'table' then
		-- Toggle Same Extras Mode
		if extra_id.toggle ~= nil then
			-- Toggle Multiple Extras
			if type(extra_id.toggle) == 'table' then
				for i, singe_extra_id in ipairs(extra_id.toggle) do
					UTIL:TogVehicleExtras(veh, singe_extra_id, state, extra_id.repair)
				end
			-- Toggle a Single Extra (no table)
			else
				UTIL:TogVehicleExtras(veh, extra_id.toggle, state, extra_id.repair)
			end
		-- Toggle Different Extras Mode
		elseif extra_id.add ~= nil and extra_id.remove ~= nil then
			if type(extra_id.add) == 'table' then
				for i, singe_extra_id in ipairs(extra_id.add) do
					UTIL:TogVehicleExtras(veh, singe_extra_id, state, extra_id.repair)
				end
			else
				UTIL:TogVehicleExtras(veh, extra_id.add, state, extra_id.repair)
			end
			if type(extra_id.remove) == 'table' then
				for i, singe_extra_id in ipairs(extra_id.remove) do
					UTIL:TogVehicleExtras(veh, singe_extra_id, not state, extra_id.repair)
				end
			else
				UTIL:TogVehicleExtras(veh, extra_id.remove, not state, extra_id.repair)
			end
		end
	else
		if state then
			if not IsVehicleExtraTurnedOn(veh, extra_id) then
				local doors =  { }
				if repair then
					for i = 0,6 do
						doors[i] = GetVehicleDoorAngleRatio(veh, i)
					end
				end
				SetVehicleAutoRepairDisabled(veh, not repair)
				SetVehicleExtra(veh, extra_id, false)
				UTIL:Print(Lang:t('info.extra_on', {extra = extra_id}), false)
				SetVehicleAutoRepairDisabled(veh, false)
				if repair then
					for i = 0,6 do
						if doors[i] > 0.0 then
							SetVehicleDoorOpen(veh, i, true, false)
						end
					end
				end
			end
		else
			if IsVehicleExtraTurnedOn(veh, extra_id) then
				SetVehicleExtra(veh, extra_id, true)
				UTIL:Print(Lang:t('info.extra_off', {extra = extra_id}), false)
			end
		end
	end
	SetVehicleAutoRepairDisabled(veh, false)
end