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
settings. 
---------------------------------------------------
]]
Citizen.CreateThread(function()
    while true do
	    RageUI.IsVisible(RMenu:Get('lvc', 'plugins'), function()
		-----------------------------------------------------------------------------------------------------------------
		if smart_siren_masterswitch then
			RageUI.Button('Smart Siren Settings', "Open smart siren settings menu. (smart_sirens)", {RightLabel = "→→→"}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'smartsiren'))	
		end
		-----------------------------------------------------------------------------------------------------------------
		if tkd_masterswitch then
			RageUI.Button('Takedown Settings', "Open takedown lights menu. (takedowns)", {RightLabel = "→→→"}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'tkdsettings'))	
		end
		-----------------------------------------------------------------------------------------------------------------
		if extra_integration_masterswitch then
			RageUI.Button('Extra Integration Settings', "Open extra integration menu. (extra_integration)", {RightLabel = "→→→"}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'extrasettings'))	
		end		
		-----------------------------------------------------------------------------------------------------------------		
		
		-----------------------------------------------------------------------------------------------------------------		
		
		-----------------------------------------------------------------------------------------------------------------		
        
		-----------------------------------------------------------------------------------------------------------------                
		end)
        Citizen.Wait(0)
	end
end)