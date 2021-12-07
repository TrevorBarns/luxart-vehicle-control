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
]]

local save_prefix = "lvc_"..community_id.."_EC_"
local backup_table

function EC:SaveSettings()
	local save_paragrams = { }
	for i, ec_toggle in pairs(EC.table) do
		local save_paragram	= { }
		save_paragram.Name = ec_toggle.Name
		save_paragram.Combo = ec_toggle.Combo
		save_paragram.Key = ec_toggle.Key
		table.insert(save_paragrams, save_paragram)
	end
	SetResourceKvp(save_prefix..EC.profile_name, json.encode(save_paragrams))
end

function EC:LoadSettings()
	local save_paragrams = GetResourceKvpString(save_prefix..EC.profile_name)
	if save_paragrams ~= nil then
		save_paragrams = json.decode(save_paragrams)
		for i, save_data in pairs(save_paragrams) do
			save_data.used = false
			for j, ec_toggle in pairs(EC.table) do
				if save_data.Name == ec_toggle.Name then
					ec_toggle.Combo = save_data.Combo
					ec_toggle.Key = save_data.Key
					save_data.used = true
				end
			end
			
			if not save_data.used then
				UTIL:Print("~b~LVC ~y~Info: found save data that did not align with current Extra Controls configuration. Likely old data that has since been changed by a server developer. You can delete this by re-saving.", true)
			end
		end
		EC:RefreshRageIndexs()
	end
end

function EC:DeleteProfiles()
	Storage:DeleteKVPs(save_prefix)
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