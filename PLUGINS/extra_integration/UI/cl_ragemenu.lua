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
if ei_masterswitch then
	RMenu.Add('lvc', 'extrasettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),' ', Lang:t('plugins.menu_ei'), 0, 0, "lvc", "lvc_plugin_logo"))
	RMenu:Get('lvc', 'extrasettings'):DisplayGlare(false)


	CreateThread(function()
		while true do
			RageUI.IsVisible(RMenu:Get('lvc', 'extrasettings'), function()
				RageUI.Checkbox(Lang:t('plugins.ei_blackout'), Lang:t('plugins.ei_blackout_desc'), EI:GetBlackOutState(), {Enabled = auto_brake_lights}, {
				onChecked = function()
					EI:SetBlackoutState(true)
				end,          
				onUnChecked = function()
					EI:SetBlackoutState(false)
				end
				})
				RageUI.List(Lang:t('plugins.ei_auto_park'), {'Off', '1/4', '1/2', '1', '5'}, EI:GetParkTimeIndex(), Lang:t('plugins.ei_auto_park_desc', {timer = ("%1.0f"):format((EI:GetStoppedTimer() / 1000) or 0)}), {}, auto_brake_lights and not EI:GetBlackOutState(), {
				  onListChange = function(Index, Item)
					if Index > 1 then
						EI:SetParkTimeIndex(Index)
						EI:SetAutoPark(true)
					else
						EI:SetParkTimeIndex(Index)
						EI:SetAutoPark(false) 
					end
				  end,
				})		
			end)
			
			Wait(0)
		end
	end)
end