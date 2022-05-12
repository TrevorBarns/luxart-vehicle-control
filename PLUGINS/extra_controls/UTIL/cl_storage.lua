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

local save_prefix = 'lvc_'..community_id..'_EC_'
local backup_table

function EC:SaveSettings()
	local save_paragrams = { }
	for i, shortcut in pairs(EC.table) do
		local save_paragram	= { }
		save_paragram.Name = shortcut.Name
		save_paragram.Combo = shortcut.Combo
		save_paragram.Key = shortcut.Key
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
						HUD:ShowNotification(('~b~LVC ~y~Warning: Unable to load control for \'%s\'. See console.'):format(shortcut.Name), true)
						UTIL:Print(('^3LVC Warning:  The saved control for \'%s\' is no longer permitted by server developer. Reverting to default. Re-save control profile to remove this error. CONTROL: %s'):format(shortcut.Name, shortcut.Combo), true)		
					end
					if  UTIL:IndexOf(CONTROLS.KEYS, shortcut.Key) then
						shortcut.Key = save_data.Key
					else
						HUD:ShowNotification(('~b~LVC ~y~Warning: Unable to load control for \'%s\'. See console.'):format(shortcut.Name), true)
						UTIL:Print(('^3LVC Warning:  The saved control for \'%s\' is no longer permitted by server developer. Reverting to default. Re-save control profile to remove this error. CONTROL: %s'):format(shortcut.Name, shortcut.Key), true)		
					end
					save_data.used = true
				end
			end
		end
		
		for i, save_data in pairs(save_paragrams) do		
			if not save_data.used then
				UTIL:Print('^3LVC Info: found save data that did not align with current Extra Controls configuration. Likely old data that has since been changed by a server developer. You can delete this by re-saving.', true)
			end
		end
		EC:RefreshRageIndexs()
	end
end

function EC:DeleteProfiles()
	STORAGE:DeleteKVPs(save_prefix)
end

function EC:RefreshRageIndexs()
	for i, extra_shortcut in ipairs(EC.table) do
		EC.combo_id[i] = UTIL:IndexOf(CONTROLS.COMBOS, EC.table[i].Combo)
		EC.key_id[i] = UTIL:IndexOf(CONTROLS.KEYS, EC.table[i].Key)
	end
end

function EC:SetBackupTable()
	backup_table = json.encode(EC.table)
end

function EC:LoadBackupTable()
	EC.table = json.decode(backup_table)
	EC:RefreshRageIndexs()
end