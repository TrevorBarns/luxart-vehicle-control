--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_storage.lua
PURPOSE: Handle plugin storage.
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
if ec_masterswitch then
	local save_prefix = 'lvc_'..community_id..'_EC_'
	local backup_table

	function EC:SaveSettings()
		local save_paragrams = { }
		for i, shortcut in pairs(EC.table) do
			local save_paragram	= { }
			save_paragram.Name = shortcut.Name
			save_paragram.Combo = shortcut.Combo
			save_paragram.Key = shortcut.Key
			save_paragram.Controller_Support = shortcut.Controller_Support
			table.insert(save_paragrams, save_paragram)
		end
		SetResourceKvp(save_prefix..EC.profile, json.encode(save_paragrams))
	end

	function EC:LoadSettings()
		local save_paragrams = GetResourceKvpString(save_prefix..EC.profile)
		if save_paragrams ~= nil then
			save_paragrams = json.decode(save_paragrams)
			--Iterate through all EC tables in save_paragrams (KVP table)
			for i, save_data in pairs(save_paragrams) do
				save_data.used = false
				--Iterate through current EC table (does the extra specific shortcut still exist)
				for j, shortcut in pairs(EC.table) do
					if save_data.Name == shortcut.Name then
						if UTIL:IndexOf(CONTROLS.COMBOS, shortcut.Combo) ~= nil then
							shortcut.Combo = save_data.Combo
						else
							UTIL:Print(Lang:t('plugins.ec_fail_load_console', { name = shortcut.Name, control = shortcut.Combo }), true)		
							HUD:ShowNotification(Lang:t('plugins.ec_fail_load_frontend', { name = shortcut.Name }), true)
						end
						if  UTIL:IndexOf(CONTROLS.KEYS, shortcut.Key) then
							shortcut.Key = save_data.Key
						else
							UTIL:Print(Lang:t('plugins.ec_fail_load_console', { name = shortcut.Name, control = shortcut.Key }), true)		
							HUD:ShowNotification(Lang:t('plugins.ec_fail_load_frontend', { name = shortcut.Name }), true)
						end
						if shortcut.Controller_Support ~= nil then
							shortcut.Controller_Support = save_data.Controller_Support
						end						
						save_data.used = true
					end
				end
			end
			
			for i, save_data in pairs(save_paragrams) do		
				if not save_data.used then
					UTIL:Print(Lang:t('plugins.ec_save_not_used'), true)
				end
			end
			EC:RefreshRageIndexs()
		end
	end

	function EC:DeleteProfiles()
		STORAGE:DeleteKVPs(save_prefix)
	end

	function EC:SetBackupTable()
		--[[set default parameters if missing from backup]]
		for i, tog_table in pairs(EC.table) do
			if tog_table.Audio == nil then
				tog_table.Audio = false
			end
			if tog_table.Controller_Support == nil then
				tog_table.Controller_Support = true
			end
		end
	end

	function EC:LoadBackupTable()
		EC.table = json.decode(backup_table)
		EC:RefreshRageIndexs()
	end
end