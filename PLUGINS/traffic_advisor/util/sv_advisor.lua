RegisterServerEvent("lvc:SetTAState_s")
AddEventHandler("lvc:SetTAState_s", function(newstate)
  TriggerClientEvent("lvc:SetTAState_c", -1, source, newstate)
end)