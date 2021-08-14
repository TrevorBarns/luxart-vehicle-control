--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_hud.lua
PURPOSE: All HUD functions, callbacks, and GTA V 
		 front-end functions.
---------------------------------------------------
]]
HUD = { }

local show_HUD = hud_first_default
local HUD_temp_hidden = false
local HUD_scale
local HUD_pos 

---------------------------------------------------------------------
--[[Gets initial HUD scale from JS]]
Citizen.CreateThread(function()
	Citizen.Wait(1000)
	SendNUIMessage({
	  _type = "hud:getHudScale",
	})
end)

---------------------------------------------------------------------
--[[Handles hiding hud when hud is hidden or game is paused.]]
Citizen.CreateThread(function()
	while true do
		if show_HUD or HUD_temp_hidden then
			if (not player_is_emerg_driver) or (IsHudHidden() == 1) or (IsPauseMenuActive() == 1) then
				HUD:SetHudState(false, true)
				HUD_temp_hidden = true
			elseif player_is_emerg_driver and (IsHudHidden() ~= 1) and (IsPauseMenuActive() ~= 1) then
				HUD:SetHudState(true, true)
				HUD_temp_hidden = false
			end
		end
		Citizen.Wait(500)
	end
end)

------------------------------------------------
--[[Getter for HUD State (whether hud is enabled).]]
function HUD:GetHudState()
	return show_HUD
end

--[[Setter for HUD State temp changes the state temporarily for pausing/hud hiding.]]
function HUD:SetHudState(state, temporary)
	local temporary = temporary or false
	if not temporary then
		show_HUD = state
	end
	HUD:SetItemState("hud", state)
end

------------------------------------------------
--[[Getter for HUD scale. Updates local save from JS and returns.]]
function HUD:GetHudScale()
	SendNUIMessage({
	  _type = "hud:getHudScale"
	})
	HUD_scale = HUD_scale or 0.6
	return HUD_scale
end

--[[Setter for HUD scale. Updates JS & CSS.]]
function HUD:SetHudScale(scale)
	if scale ~= nil then
		SendNUIMessage({
		  _type = "hud:setHudScale",
		  scale = scale,
		})
	end
end

--[[Callback for JS -> LUA to set HUD_scale with current CSS]]
RegisterNUICallback( "hud:sendHudScale", function(scale, cb)
	HUD_scale = scale
end )

------------------------------------------------
--[[Toggles HUD images based on their state on/off]]
function HUD:SetItemState(item, state)
	SendNUIMessage({
	  _type = "hud:setItemState",
	  item  = item,
	  state = state
	})
end
------------------------------------------------
--[[Setter for HUD position, used when loading save data.]]
function HUD:SetHudPosition(data)
	HUD_pos = data
	SendNUIMessage({
	  _type = "hud:setHudPosition",
	  pos = HUD_pos,
	})	
end

--[[Getter for HUD position, used when saving data.]]
function HUD:GetHudPosition()
	return HUD_pos
end

--[[Sets HUD position based off backup stored in JS, in case HUD is off screen.]]
function HUD:ResetPosition()
	SendNUIMessage({
	  _type = "hud:resetPosition",
	})
end

--[[Callback for JS -> LUA to set HUD_pos with current position to save.]]
RegisterNUICallback( "hud:setHudPositon", function(data, cb)
	HUD_pos = data
	Storage:SaveHUDSettings()
end )

------------------------------------------------
--[[Sets NUI focus for move mode.]]
function HUD:SetMoveMode(state)
	SetNuiFocus( state, state )
end

--[[Sets NUI focus to false when right-click, esc, etc. are clicked.]]
RegisterNUICallback( "hud:setMoveState", function(state, cb)
	SetNuiFocus(state, state)
end )

------------------------------------------------
--On screen GTA V notification
function HUD:ShowNotification(text, override)
	override = override or false
	if GetResourceMetadata(GetCurrentResourceName(), 'debug_mode', 0) == 'true' or override then
		SetNotificationTextEntry("STRING")
		AddTextComponentString(text)
		DrawNotification(false, true)
	end
end

------------------------------------------------
--Drawn On Screen Text at X, Y
function HUD:ShowText(x, y, align, text, scale, label)
	scale = scale or 0.4
	SetTextJustification(align)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, scale)
	SetTextColour(128, 128, 128, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	if text ~= nil then
		SetTextEntry("STRING")
		AddTextComponentString(text)
	else
		SetTextEntry(label)
	end
	DrawText(x, y)
	ResetScriptGfxAlign()
end

------------------------------------------------
--Full screen Confirmation Message
function HUD:FrontEndAlert(title, subtitle)
	AddTextEntry("FACES_WARNH2", "Warning")
	AddTextEntry("QM_NO_0", "Are you sure you want to delete all saved LVC data and Factory Reset?")
	local result = -1
	while result == -1 do
		DrawFrontendAlert("FACES_WARNH2", "QM_NO_0", 0, 0, "", 0, -1, 0, "", "", false, 0)
		HUD:ShowText(0.5, 0.75, 0, "~g~No: Escape \t ~r~Yes: Enter", 0.75)
		if IsDisabledControlJustReleased(2, 202) then
			return false
		end		
		if IsDisabledControlJustReleased(2, 201) then
			return true
		end
		Citizen.Wait(0)
	end
end

------------------------------------------------
--Get User Input from Keyboard
function HUD:KeyboardInput(input_title, existing_text, max_length)
	AddTextEntry('Custom_Keyboard_Title', input_title)
	DisplayOnscreenKeyboard(1, "Custom_Keyboard_Title", "", existing_text, "", "", "", max_length) 

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(0)
	end
		
	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult() 
		Citizen.Wait(500) 
		if result ~= "" then
			return result 
		else 
			return nil
		end
	else
		Citizen.Wait(500)
		return nil 
	end
end