--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
Traffic Advisor Plugin by Dawson
---------------------------------------------------
FILE: server.lua
PURPOSE: Handle version checking, syncing sirens,
and opening links.
---------------------------------------------------
]]
RegisterServerEvent("lvc:SetTAState_s")
AddEventHandler("lvc:SetTAState_s", function(newstate)
  TriggerClientEvent("lvc:SetTAState_c", -1, source, newstate)
end)