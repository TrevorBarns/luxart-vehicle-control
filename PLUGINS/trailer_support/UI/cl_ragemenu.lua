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

RMenu.Add('lvc', 'trailersettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),' ', Lang:t('plugins.menu_ts'), 0, 0, "lvc", "lvc_plugin_logo"))
RMenu.Add('lvc', 'trailerextras', RageUI.CreateSubMenu(RMenu:Get('lvc', 'trailersettings'),' ', Lang:t('plugins.ts_menu_extras'), 0, 0, "lvc", "lvc_plugin_logo"))
RMenu.Add('lvc', 'trailerdoors', RageUI.CreateSubMenu(RMenu:Get('lvc', 'trailersettings'),' ', Lang:t('plugins.ts_menu_doors'), 0, 0, "lvc", "lvc_plugin_logo"))
RMenu:Get('lvc', 'trailersettings'):DisplayGlare(false)
RMenu:Get('lvc', 'trailerextras'):DisplayGlare(false)
RMenu:Get('lvc', 'trailerdoors'):DisplayGlare(false)

local doors = { Lang:t('plugins.ts_door_fl'), Lang:t('plugins.ts_door_fr'), Lang:t('plugins.ts_door_rl'), Lang:t('plugins.ts_door_rr'), Lang:t('plugins.ts_door_hood'), Lang:t('plugins.ts_door_trunk'), Lang:t('plugins.ts_door_extra1'), Lang:t('plugins.ts_door_extra2'), Lang:t('plugins.ts_door_bombbay') }
local trailer_set = false

CreateThread(function()
    while true do
		if trailer ~= nil and trailer ~= 0 then
			trailer_set = true
		else
			trailer_set = false
		end
	
		RageUI.IsVisible(RMenu:Get('lvc', 'trailersettings'), function()	
			--Current Trailer Display
			RageUI.Button(Lang:t('plugins.ts_current'), Lang:t('plugins.ts_current_desc'), {RightLabel = TRAIL:GetTrailerDisplayName()}, true, {
			  onSelected = function()
			  end,
			})	
			
			--Custom Toggle Buttons
			if TRAIL.custom_toggles_set then
				RageUI.Separator(Lang:t('plugins.ts_shortcut_separator'))
				for i, custom_tog_table in ipairs(TRAIL.TBL) do
					RageUI.Button(custom_tog_table[1], Lang:t('plugins.ts_shortcut_desc', { shortcut = custom_tog_table[1] }), { }, trailer_set, {
					  onSelected = function()
						for i, custom_tog in pairs(custom_tog_table[2]) do
							TRAIL:SetExtraState(custom_tog.Trailer, custom_tog.Extra, custom_tog.State)
						end
					  end,
					})						
				end
			end
			
			RageUI.Separator(Lang:t('plugins.ts_submenus_separator'))
		
			-- Sub Menu Buttons			
			RageUI.Button(Lang:t('plugins.ts_menu_extras_button'), Lang:t('plugins.ts_menu_extras_desc'), {RightLabel = '→→→'}, trailer_set, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'trailerextras'))	
			RageUI.Button(Lang:t('plugins.ts_menu_doors_button'), Lang:t('plugins.ts_menu_doors_desc'), {RightLabel = '→→→'}, trailer_set, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'trailerdoors'))	
        end)		
		
		
			--EXTRAS MENU
			RageUI.IsVisible(RMenu:Get('lvc', 'trailerextras'), function()
				RageUI.Separator(Lang:t('plugins.ts_truck_separator'))			
				for extra_id=1,14 do
					if DoesEntityExist(veh) then
						if DoesExtraExist(veh, extra_id) then
							RageUI.Checkbox(Lang:t('plugins.ts_extra', { extra = extra_id }), Lang:t('plugins.ts_extra_desc', { extra = extra_id }), IsVehicleExtraTurnedOn(veh, extra_id), {}, {
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
				RageUI.Separator(Lang:t('plugins.ts_trailer_separator'))			
				for extra_id=1,14 do
					if DoesEntityExist(trailer) then
						if DoesExtraExist(trailer, extra_id) then
							RageUI.Checkbox(Lang:t('plugins.ts_extra', { extra = extra_id }), Lang:t('plugins.ts_extra_desc', { extra = extra_id }), IsVehicleExtraTurnedOn(trailer, extra_id), {}, {
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
				RageUI.Separator(Lang:t('plugins.ts_truck_separator'))			
				for door_num, door_name in ipairs(doors) do
					door_num = door_num-1
					if DoesVehicleHaveDoor(veh, door_num) then
						RageUI.Button(door_name, Lang:t('plugins.ts_door_desc', { door = door_name }), {}, true, {
						onSelected = function()
							if GetVehicleDoorAngleRatio(veh, door_num) > 0 then
								SetVehicleDoorShut(veh, door_num, true)
							else
								SetVehicleDoorOpen(veh, door_num, true, false)
							end
						end,
						})
					end
				end
				RageUI.Separator(Lang:t('plugins.ts_trailer_separator'))			
				for door_num, door_name in ipairs(doors) do
					door_num = door_num-1
					if DoesVehicleHaveDoor(trailer, door_num) then
						RageUI.Button(door_name, Lang:t('plugins.ts_door_desc', { door = door_name }), {}, true, {
						onSelected = function()
							if GetVehicleDoorAngleRatio(trailer, door_num) > 0 then
								SetVehicleDoorShut(trailer, door_num, true)
							else
								SetVehicleDoorOpen(trailer, door_num, true, false)
							end
						end,
						})
					end
				end
			end)
	Wait(0)
	end
end)