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
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local veh_name_wildcard = string.gsub(veh_name, "%d+", "#")

	if SIREN_ASSIGNMENTS[veh_name] ~= nil then							--Does profile exist as outlined in vehicle.meta
		approved_tones = SIREN_ASSIGNMENTS[veh_name]
		profile = veh_name
	elseif SIREN_ASSIGNMENTS[veh_name_wildcard] ~= nil then				--Does profile exist using # as wildcard for any digits.
		approved_tones = SIREN_ASSIGNMENTS[veh_name_wildcard]
		profile = veh_name_wildcard
	else 
		approved_tones = SIREN_ASSIGNMENTS['DEFAULT']
		profile = 'DEFAULT'
		HUD:ShowNotification("~b~LVC~s~: Using ~b~DEFAULT~s~ profile for \"~o~"..veh_name.."~s~\".", false)
	end
	
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
		option = SIRENS[id].Option or 1
		temp_array[id] = option
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
	if approved_tones ~= nil then
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
			HUD:ShowNotification("~b~LVC ~y~Warning 403:~s~ Too little sirens assigned.", false)
			UTIL:Print("Warning 403: Too little sirens assigned. (UTIL:SetToneByPos("..tone_string..", "..pos..")", true)
		end
	else
		HUD:ShowNotification("~b~LVC ~y~Warning 404:~s~ Attempted to set tone but, was unable to located approved_tones. See console.", false)
		UTIL:Print("^3Warning 404: Attempted to set tone "..tone_string.." but, was unable to located pos: "..pos.." in approved_tones. (UTIL:SetToneByPos("..tone_string..", "..pos..")", true)
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
function UTIL:SetToneByID(tone, tone_id)
	if UTIL:IsApprovedTone(tone_id) then
		if tone == 'MAIN_MEM' then
			tone_main_mem_id = tone_id
		elseif tone == 'PMANU' then
			tone_PMANU_id = tone_id
		elseif tone == 'SMANU' then
			tone_SMANU_id = tone_id
		elseif tone == 'AUX' then
			tone_AUX_id = tone_id
		elseif tone == 'ARHRN' then
			tone_ARHRN_id = tone_id
		end
	else
		HUD:ShowNotification("~b~LVC ~y~Warning 504:~s~ Attempted to set tone but, was unable to located approved_tones. See console.", false)
		UTIL:Print("Warning 504: Attempted to set tone "..tone_string.." but, was unable to located pos: "..pos.."in approved_tones. (UTIL:SetToneByPos("..tone_string..", "..pos..")", true)
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
	Storage:SetCustomToneStrings(true)
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
	if GetResourceMetadata(GetCurrentResourceName(), 'debug_mode', 0) == 'true' or override then
		print(string)
	end
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
				UTIL:Print("UTIL:: Toggling extra "..extra_id.." on", false)
				SetVehicleAutoRepairDisabled(veh, repair)
				if repair then
					for i = 0,6 do
						if doors[i] > 0.0 then
							SetVehicleDoorOpen(veh, i, false, false)
						end
					end
				end
			end
		else
			if IsVehicleExtraTurnedOn(veh, extra_id) then
				SetVehicleExtra(veh, extra_id, true)
				UTIL:Print("UTIL:: Toggling extra "..extra_id.." off", false)
			end	
		end
	end
	SetVehicleAutoRepairDisabled(veh, false)
end