--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
Traffic Advisor Plugin by Dawson
---------------------------------------------------
FILE: cl_advisor.lua
PURPOSE: Contains threads, functions to 
change traffic advisor state through extras.
---------------------------------------------------
]]
TA = {}
local taExtras = {}
state_ta = {}

if ta_masterswitch then
	RegisterCommand('lvctogleftta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if player_is_emerg_driver and taExtras.lightbar ~= nil and veh ~= nil then
				if IsVehicleExtraTurnedOn(veh, taExtras.lightbar) and IsVehicleSirenOn(veh) then
					if state_ta[veh] == 1 then
						TA:TogVehicleExtras(veh, taExtras.left.off, true)
						PlayAudio("Downgrade", downgrade_volume)
						state_ta[veh] = 0
					else
						TA:TogVehicleExtras(veh, taExtras.left.on, true)
						PlayAudio("Upgrade", upgrade_volume)
						state_ta[veh] = 1
					end
				end
			end
		end
	end)
	
	RegisterCommand('lvctogrightta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if taExtras.lightbar ~= nil and veh ~= nil then
				if IsVehicleExtraTurnedOn(veh, taExtras.lightbar) and IsVehicleSirenOn(veh) then
				
					if state_ta[veh] == 2 then
						TA:TogVehicleExtras(veh, taExtras.right.off, true)
						PlayAudio("Downgrade", downgrade_volume)
						state_ta[veh] = 0
					else
						TA:TogVehicleExtras(veh, taExtras.right.on, true)
						PlayAudio("Upgrade", upgrade_volume)
						state_ta[veh] = 2
					end
				end
			end
		end
	end)
	
	RegisterCommand('lvctogmidta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if taExtras.lightbar ~= nil and veh ~= nil then
				if IsVehicleExtraTurnedOn(veh, taExtras.lightbar) and IsVehicleSirenOn(veh) then
					if state_ta[veh] == 3 then
						TA:TogVehicleExtras(veh, taExtras.middle.off, true)
						PlayAudio("Downgrade", downgrade_volume)
						state_ta[veh] = 0
					else
						TA:TogVehicleExtras(veh, taExtras.middle.on, true)
						PlayAudio("Upgrade", upgrade_volume)
						state_ta[veh] = 3
					end
				end
			end
		end
	end)

	RegisterKeyMapping('lvctogleftta', 'LVC Toggle Left TA', 'keyboard', 'left')
	RegisterKeyMapping('lvctogrightta', 'LVC Toggle Right TA', 'keyboard', 'right')
	RegisterKeyMapping('lvctogmidta', 'LVC Toggle Middle TA', 'keyboard', 'down')

	Citizen.CreateThread(function()
		TriggerEvent('chat:removeSuggestion', '/lvctogleftta')
		TriggerEvent('chat:removeSuggestion', '/lvctogrightta')
		TriggerEvent('chat:removeSuggestion', '/lvctogmidta')
	end)
end

function TA:TogVehicleExtras(veh, extra_id, state, repair)
	local repair = repair or false
	if type(extra_id) == 'table' then
		-- Toggle Same Extras Mode
		if extra_id.toggle ~= nil then
			-- Toggle Multiple Extras
			if type(extra_id.toggle) == 'table' then
				for i, singe_extra_id in ipairs(extra_id.toggle) do
					TogVehicleExtras(veh, singe_extra_id, state, extra_id.repair)
				end
			-- Toggle a Single Extra (no table)
			else
				TogVehicleExtras(veh, extra_id.toggle, state, extra_id.repair)
			end
		-- Toggle Different Extras Mode
		else
			if extra_id.add ~= nil then 
				if type(extra_id.add) == 'table' then
					for i, singe_extra_id in ipairs(extra_id.add) do
						TogVehicleExtras(veh, singe_extra_id, state, extra_id.repair)
					end
				else
					TogVehicleExtras(veh, extra_id.add, state, extra_id.repair)
				end
			if extra_id.remove ~= nil then
				if type(extra_id.remove) == 'table' then
					for i, singe_extra_id in ipairs(extra_id.remove) do
						TogVehicleExtras(veh, singe_extra_id, not state, extra_id.repair)
					end
				else
					TogVehicleExtras(veh, extra_id.remove, not state, extra_id.repair)
				end
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
				UTIL:Print("TA: Toggling extra "..extra_id.." on", false)
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
				UTIL:Print("TA: Toggling extra "..extra_id.." off", false)
			end	
		end
	end
  SetVehicleAutoRepairDisabled(veh, false)
end

Citizen.CreateThread(function()
	Citizen.Wait(500)
	EI:FixOversizeKeys()
end) 

RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	if player_is_emerg_driver and veh ~= nil then
		TA:UpdateExtrasTable(veh)
		state_ta[veh] = 0
	end
end)

function TA:FixOversizeKeys()
  for i, tbl in pairs (TA_ASSIGNMENTS) do
    if string.len(i) > 11 then
      local shortened_gameName = string.gsub(i, 1, 11)
      TA_ASSIGNMENTS[shortened_gameName] = TA_ASSIGNMENTS[i]
      TA_ASSIGNMENTS[i] = nil
    end
  end
end

function TA:UpdateExtrasTable(veh)
  local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
  if TA_ASSIGNMENTS[veh_name] ~= nil then
    taExtras = TA_ASSIGNMENTS[veh_name]
    UTIL:Print('TA: Profile found for ' .. veh_name, false)
  else
    taExtras = TA_ASSIGNMENTS['DEFAULT']
  end
end

function TA:SetTAStateForVeh(veh, newstate)
  if DoesEntityExist(veh) and not IsEntityDead(veh) then
    if newstate ~= state_ta[veh] then
      state_ta[veh] = newstate
    end
  end
end

RegisterNetEvent("lvc:SetTAState_c")
AddEventHandler("lvc:SetTAState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TA:SetTAStateForVeh(veh, newstate)
			end
		end
	end
end)