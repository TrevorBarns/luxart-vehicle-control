RegisterServerEvent("lvc_SetTAState_s")
AddEventHandler("lvc_SetTAState_s", function(newstate)
  TriggerClientEvent("lvc_SetTAState_c", -1, source, newstate)
end)