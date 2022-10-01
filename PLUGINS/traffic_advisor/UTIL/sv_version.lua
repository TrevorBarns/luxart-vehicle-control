--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: sv_version.lua
PURPOSE: Handle plugin version checking.
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

local plugin_name = 'traffic_advisor'
local plugin_version = '1.0.5'

RegisterServerEvent('lvc:plugins_getVersions') 
AddEventHandler('lvc:plugins_getVersions', function()
	TriggerEvent('lvc:plugins_storePluginVersion', plugin_name, plugin_version)
end)