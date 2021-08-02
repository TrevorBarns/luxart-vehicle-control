--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_ragemenu.lua
PURPOSE: Handle RageUI 
---------------------------------------------------
]]

RMenu.Add('lvc', 'trailersettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),"Luxart Vehicle Control", "Trailer Options"))
RMenu.Add('lvc', 'trailerextras', RageUI.CreateSubMenu(RMenu:Get('lvc', 'trailersettings'),"Luxart Vehicle Control", "Trailer Extras"))
RMenu.Add('lvc', 'trailerdoors', RageUI.CreateSubMenu(RMenu:Get('lvc', 'trailersettings'),"Luxart Vehicle Control", "Trailer Extras"))
RMenu:Get('lvc', 'trailersettings'):DisplayGlare(false)
RMenu:Get('lvc', 'trailerextras'):DisplayGlare(false)
RMenu:Get('lvc', 'trailerdoors'):DisplayGlare(false)

local doors = {"Left Front Door", "Right Front Door", "Left Rear Door", "Right Rear Door", "Hood", "Trunk", "Extra #1", "Extra #2", "Bomb Bay"}
local trailer_set = false

Citizen.CreateThread(function()
    while true do
		if trailer ~= nil and trailer ~= 0 then
			trailer_set = true
		else
			trailer_set = false
		end
	
		RageUI.IsVisible(RMenu:Get('lvc', 'trailersettings'), function()	
			--Current Trailer Display
			RageUI.Button('Current Trailer', "Current detected trailer attached.", {RightLabel = TRAIL:GetTrailerDisplayName()}, true, {
			  onSelected = function()
			  end,
			})	
			
			--Custom Toggle Buttons
			if TRAIL.custom_toggles_set then
				RageUI.Separator("Shortcuts")
				for i, custom_tog_table in ipairs(TRAILERS[TRAIL:GetCabDisplayName()]) do
					RageUI.Button(custom_tog_table[1], "", { }, trailer_set, {
					  onSelected = function()
						for i, custom_tog in pairs(custom_tog_table[2]) do
							TRAIL:SetExtraState(custom_tog.Trailer, custom_tog.Extra, custom_tog.State)
						end
					  end,
					})						
				end
			end
			
			RageUI.Separator("Submenus")
		
			-- Sub Menu Buttons			
			RageUI.Button('Extras Menu', "Open menu to toggle trailer extra states.", {RightLabel = "→→→"}, trailer_set, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'trailerextras'))	
			RageUI.Button('Doors Menu', "Open menu to open / close doors.", {RightLabel = "→→→"}, trailer_set, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'trailerdoors'))	
        end)		
		
		
			--EXTRAS MENU
			RageUI.IsVisible(RMenu:Get('lvc', 'trailerextras'), function()
				RageUI.Separator("Cab/Truck")
				for extra_id=1,14 do
					if DoesEntityExist(veh) then
						if DoesExtraExist(veh, extra_id) then
							RageUI.Checkbox('Extra #'..extra_id, "Toggle extra #"..extra_id, IsVehicleExtraTurnedOn(veh, extra_id), {}, {
							  onChecked = function()
								SetVehicleExtra(veh, extra_id, false)
							  end,          
							  onUnChecked = function()
								SetVehicleExtra(veh, extra_id, true)
							  end
							})		
						end
					end
				end
				RageUI.Separator("Trailer")
				for extra_id=1,14 do
					if DoesEntityExist(trailer) then
						if DoesExtraExist(trailer, extra_id) then
							RageUI.Checkbox('Extra #'..extra_id, "Toggle extra #"..extra_id, IsVehicleExtraTurnedOn(trailer, extra_id), {}, {
							  onChecked = function()
								SetVehicleExtra(trailer, extra_id, false)
							  end,          
							  onUnChecked = function()
								SetVehicleExtra(trailer, extra_id, true)
							  end
							})		
						end
					end
				end
			end)			
			
			--DOORS MENU
			RageUI.IsVisible(RMenu:Get('lvc', 'trailerdoors'), function()
				RageUI.Separator("Cab/Truck")			
				for door_num, door_name in ipairs(doors) do
					door_num = door_num-1
					if DoesVehicleHaveDoor(veh, door_num) then
						RageUI.Button(door_name, "Open / close "..string.lower(door_name)..".", {}, true, {
						onSelected = function()
							if GetVehicleDoorAngleRatio(veh, door_num) > 0 then
								SetVehicleDoorShut(veh, door_num, true)
							else
								SetVehicleDoorOpen(veh, door_num, false, false)
							end
						end,
						})
					end
				end
				RageUI.Separator("Trailer")			
				for door_num, door_name in ipairs(doors) do
					door_num = door_num-1
					if DoesVehicleHaveDoor(trailer, door_num) then
						RageUI.Button(door_name, "Open / close "..string.lower(door_name)..".", {}, true, {
						onSelected = function()
							print(GetVehicleDoorAngleRatio(trailer, door_num))
							if GetVehicleDoorAngleRatio(trailer, door_num) > 0 then
								SetVehicleDoorShut(trailer, door_num, true)
							else
								SetVehicleDoorOpen(trailer, door_num, false, false)
							end
						end,
						})
					end
				end
			end)
	Citizen.Wait(0)
	end
end)