--[[
	PORTIONS OF THE CODE BELOW WAS CREATED BY WolfKnight IN THE WIDELY POPULAR BRRAKELIGHTS RESOURCE.
	THANKS FOR HIS PERMISSION TO ADAPT FOR USE AND DISTRIBUTION WITH LVC FOR EXTRA INTEGRATION SUPPORT.

	https://forum.cfx.re/t/release-vehicle-brake-lights-1-0-2-client-sync-updated-2019/15322

	Copyright (c) 2022 TrevorBarns
	Copyright (c) 2017-2022 WolfKnight
]]
if auto_brake_lights then
	local ped = nil
	local vehicle = nil
	
	CreateThread( function()
		while true do 
			ped = GetPlayerPed( -1 )
			if DoesEntityExist( ped ) and not IsEntityDead( ped ) and IsPedSittingInAnyVehicle( ped ) then 
				vehicle = GetVehiclePedIsIn( ped, false )
				if GetPedInVehicleSeat( vehicle, -1 ) == ped then
					if not EI.blackout and not EI.auto_park_state then
						if GetVehicleClass( veh ) ~= 14 and GetVehicleClass( veh ) ~= 15 and GetVehicleClass( veh ) ~= 16 and GetVehicleClass( veh ) ~= 21 then 
							if ( GetEntitySpeed( vehicle ) < 0.1 and GetIsVehicleEngineRunning( vehicle ) ) then 
								SetVehicleBrakeLights( vehicle, true )
							end 
						end
					else
						SetVehicleBrakeLights(vehicle, false)
					end
				else
					Wait(500)
				end 
			else
				Wait(500)
			end
			Wait(1)
		end
	end )
end