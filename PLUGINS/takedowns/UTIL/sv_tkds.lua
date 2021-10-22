--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: server.lua
PURPOSE: Handle version checking, syncing sirens,
and opening links.
---------------------------------------------------
]]
RegisterServerEvent('lvc:TogTkdState_s')
AddEventHandler('lvc:TogTkdState_s', function(newstate)
	TriggerClientEvent('lvc:TogTkdState_c', -1, source, newstate)
end)
