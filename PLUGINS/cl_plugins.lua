--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_plugins.lua
PURPOSE: Builds RageUI Plugin Menu based on plugins
settings. Handles Plugin -> LVC event communication
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
local cached_plugins_menu = nil
local cached_tkdsettings = nil
local cached_extrasettings = nil
local cached_tasettings = nil
local cached_trailersettings = nil
local cached_trailerextras = nil
local cached_trailerdoors = nil
local cached_extracontrols = nil

CreateThread(function()
	Wait(500)
	cached_plugins_menu = RMenu:Get('lvc', 'plugins')
	cached_tkdsettings = RMenu:Get('lvc', 'tkdsettings')
	cached_extrasettings = RMenu:Get('lvc', 'extrasettings')
	cached_tasettings = RMenu:Get('lvc', 'tasettings')
	cached_trailersettings = RMenu:Get('lvc', 'trailersettings')
	cached_trailerextras = RMenu:Get('lvc', 'trailerextras')
	cached_trailerdoors = RMenu:Get('lvc', 'trailerdoors')
	cached_extracontrols = RMenu:Get('lvc', 'extracontrols')
end)

CreateThread(function()
	while true do
		if plugins_installed and cached_plugins_menu and IsMenuOpen() and RageUI.Visible(cached_plugins_menu) then
			RageUI.IsVisible(cached_plugins_menu, function()
				if tkd_masterswitch ~= nil then
					RageUI.Button(Lang:t('plugins.menu_tkd'), Lang:t('plugins.menu_tkd_desc'), {RightLabel = '→→→'}, tkd_masterswitch, {
					  onSelected = function()
					  end,
					}, cached_tkdsettings)
				end
				if ei_masterswitch ~= nil then
					RageUI.Button(Lang:t('plugins.menu_ei'), Lang:t('plugins.menu_ei_desc'), {RightLabel = '→→→'}, ei_masterswitch, {
					  onSelected = function()
					  end,
					}, cached_extrasettings)
				end
				if ta_masterswitch ~= nil then
					RageUI.Button(Lang:t('plugins.menu_ta'), Lang:t('plugins.menu_ta_desc'), {RightLabel = '→→→'}, ta_masterswitch, {
					  onSelected = function()
					  end,
					}, cached_tasettings)
				end
				if trailer_masterswitch ~= nil then
					RageUI.Button(Lang:t('plugins.menu_ts'), Lang:t('plugins.menu_ts_desc'), {RightLabel = '→→→'}, trailer_masterswitch, {
					  onSelected = function()
					  end,
					}, cached_trailersettings)
				end
				if ec_masterswitch ~= nil then
					RageUI.Button(Lang:t('plugins.menu_ec'), Lang:t('plugins.menu_ec_desc'), {RightLabel = '→→→'}, ec_masterswitch, {
					  onSelected = function()
					  end,
					}, cached_extracontrols)
				end
			end)
			Wait(0)
		else
			Wait(500)
		end
	end
end)

local ec_shortcut_menu_visible = false
function IsPluginMenuOpen()
	if ec_masterswitch then
		ec_shortcut_menu_visible = EC.is_menu_open
	end

	return  (cached_tkdsettings and RageUI.Visible(cached_tkdsettings)) or
			(cached_extrasettings and RageUI.Visible(cached_extrasettings)) or
			(cached_tasettings and RageUI.Visible(cached_tasettings)) or
			(cached_trailersettings and RageUI.Visible(cached_trailersettings)) or
			(cached_trailerextras and RageUI.Visible(cached_trailerextras)) or
			(cached_trailerdoors and RageUI.Visible(cached_trailerdoors)) or
			(cached_extracontrols and RageUI.Visible(cached_extracontrols)) or
			ec_shortcut_menu_visible
end
