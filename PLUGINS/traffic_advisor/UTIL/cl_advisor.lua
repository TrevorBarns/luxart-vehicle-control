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
local temp_hud_disable
preserve_ta_state = false
state_ta = {}

Citizen.CreateThread(function()
	while ta_masterswitch do 
		if player_is_emerg_driver then
			if state_ta[veh] ~= nil and state_ta[veh] > 0 then
				if not IsVehicleSirenOn(veh) and not temp_hud_disable then
					HUD:SetItemState("ta", false)
					temp_hud_disable = true
					if not save_ta_state then
						UTIL:TogVehicleExtras(veh, taExtras.middle.off, true)
						state_ta[veh] = 0
					end
				elseif IsVehicleSirenOn(veh) and temp_hud_disable then
					HUD:SetItemState("ta", state_ta[veh])
					temp_hud_disable = false
				end
			else
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(500)
		end
		Citizen.Wait(0)
	end
end) 

if ta_masterswitch then
	RegisterCommand('lvctogleftta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if player_is_emerg_driver and ( taExtras.lightbar ~= nil or taExtras.lightbar == -1 ) and veh ~= nil and not IsMenuOpen() then
				if ( IsVehicleExtraTurnedOn(veh, taExtras.lightbar) or taExtras.lightbar == -1 ) and IsVehicleSirenOn(veh) then
					if state_ta[veh] == 1 then
						UTIL:TogVehicleExtras(veh, taExtras.left.off, true)
						PlayAudio("Downgrade", downgrade_volume)
						state_ta[veh] = 0
					else
						UTIL:TogVehicleExtras(veh, taExtras.left.on, true)
						PlayAudio("Upgrade", upgrade_volume)
						state_ta[veh] = 1
					end
					HUD:SetItemState("ta", state_ta[veh]) 					
				end
			end
		end
	end)
	
	RegisterCommand('lvctogrightta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if player_is_emerg_driver and ( taExtras.lightbar ~= nil or taExtras.lightbar == -1 ) and veh ~= nil and not IsMenuOpen() then
				if ( IsVehicleExtraTurnedOn(veh, taExtras.lightbar) or taExtras.lightbar == -1 ) and IsVehicleSirenOn(veh) then
					if state_ta[veh] == 2 then
						UTIL:TogVehicleExtras(veh, taExtras.right.off, true)
						PlayAudio("Downgrade", downgrade_volume)
						state_ta[veh] = 0
					else
						UTIL:TogVehicleExtras(veh, taExtras.right.on, true)
						PlayAudio("Upgrade", upgrade_volume)
						state_ta[veh] = 2
					end
					HUD:SetItemState("ta", state_ta[veh]) 
				end
			end
		end
	end)
	
	RegisterCommand('lvctogmidta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if player_is_emerg_driver and ( taExtras.lightbar ~= nil or taExtras.lightbar == -1 ) and veh ~= nil and not IsMenuOpen() then
				if ( IsVehicleExtraTurnedOn(veh, taExtras.lightbar) or taExtras.lightbar == -1 ) and IsVehicleSirenOn(veh) then
					if state_ta[veh] == 3 then
						UTIL:TogVehicleExtras(veh, taExtras.middle.off, true)
						PlayAudio("Downgrade", downgrade_volume)
						state_ta[veh] = 0
					else
						UTIL:TogVehicleExtras(veh, taExtras.middle.on, true)
						PlayAudio("Upgrade", upgrade_volume)
						state_ta[veh] = 3
					end
					HUD:SetItemState("ta", state_ta[veh]) 					
				end
			end
		end
	end)

	RegisterKeyMapping('lvctogleftta', 'LVC Toggle Left TA', 'keyboard', 'left')
	RegisterKeyMapping('lvctogrightta', 'LVC Toggle Right TA', 'keyboard', 'right')
	RegisterKeyMapping('lvctogmidta', 'LVC Toggle Middle TA', 'keyboard', 'down')
end

Citizen.CreateThread(function()
	Citizen.Wait(500)
	UTIL:FixOversizeKeys(TA_ASSIGNMENTS)
end) 

RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	if player_is_emerg_driver and veh ~= nil then
		TA:UpdateExtrasTable(veh)
		state_ta[veh] = 0
	end
end)

function TA:UpdateExtrasTable(veh)
  local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
  local veh_name_wildcard = string.gsub(veh_name, "%d+", "#")

  if TA_ASSIGNMENTS[veh_name] ~= nil then
    taExtras = TA_ASSIGNMENTS[veh_name]
    UTIL:Print('TA: Profile found for ' .. veh_name, false)
  elseif TA_ASSIGNMENTS[veh_name_wildcard] ~= nil then
    taExtras = TA_ASSIGNMENTS[veh_name_wildcard]
    UTIL:Print('TA: Wildcard profile found for ' .. veh_name, false)
  else
    taExtras = TA_ASSIGNMENTS['DEFAULT']
  end
  
  hud_pattern = taExtras.hud_pattern or 1
  HUD:SetItemState("ta_pattern", hud_pattern)
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
