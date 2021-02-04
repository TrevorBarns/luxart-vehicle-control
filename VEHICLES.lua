--[[
---------------------------------------------------
LUXART VEHICLE CONTROL (FOR FIVEM)
---------------------------------------------------
Last revision: DECEMBER 26 2020  (VERS.3.1.6)
Coded by Lt.Caine
ELS Clicks by Faction
Additions by TrevorBarns
---------------------------------------------------
FILE: vehicles.lua
PURPOSE: Associate specific sirens with specific
vehicles. Siren assignements. 
---------------------------------------------------
SIREN TONE TABLE: 
	ID- Generic Name	(SIREN STRING)									[vehicles.awc name]
	1 - Airhorn 		(SIRENS_AIRHORN)								[AIRHORN_EQD]
	2 - Wail 			(VEHICLES_HORNS_SIREN_1)						[SIREN_PA20A_WAIL]
	3 - Yelp 			(VEHICLES_HORNS_SIREN_2)						[SIREN_2]
	4 - Priority 		(VEHICLES_HORNS_POLICE_WARNING)					[POLICE_WARNING]
	5 - CustomA* 		(RESIDENT_VEHICLES_SIREN_WAIL_01)				[SIREN_WAIL_01]
	6 - CustomB* 		(RESIDENT_VEHICLES_SIREN_WAIL_02)				[SIREN_WAIL_02]
	7 - CustomC* 		(RESIDENT_VEHICLES_SIREN_WAIL_03)				[SIREN_WAIL_03]
	8 - CustomE* 		(RESIDENT_VEHICLES_SIREN_QUICK_01)				[SIREN_QUICK_01]
	9 - CustomF* 		(RESIDENT_VEHICLES_SIREN_QUICK_02)				[SIREN_QUICK_02]
	10 - CustomG* 		(RESIDENT_VEHICLES_SIREN_QUICK_03)				[SIREN_QUICK_03]
	11 - Powercall 		(VEHICLES_HORNS_AMBULANCE_WARNING)				[AMBULANCE_WARNING]
	12 - FireHorn	 	(VEHICLES_HORNS_FIRETRUCK_WARNING)				[FIRE_TRUCK_HORN]
	13 - Firesiren 		(RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01)		[SIREN_FIRETRUCK_WAIL_01]
	14 - Firesiren2 	(RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01)	[SIREN_FIRETRUCK_QUICK_01]

	* Notice: 	Enabling these sirens will allow players to use NEW sirens, meaning peoples siren packs need to be updated or they will hear the default sound (yuck). 
				I recommend creating/provideing instructions on how to replace these default sirens AND/OR provide premade sirenpacks. 

EXAMPLE:
['paleto1'] = {2, 3, 4, 5} 
Where 'paleto1' is the vehicele's <gameName> as defined in vehicles.meta.
]]

--Modify the table below to accurately represent each tone name
tone_table = { "Airhorn", "Wail", "Yelp", "Priority", "Futura", "Hetro", "Sweep-1", "Sweep-2", "Hi-Low", "Whine Down", "Powercall", "QSiren", "Fire Yelp", "Fire Yelp" } 
--				  1			2 		3		4			5		6		 7			8			 9			10			11			12			13				14

VEHICLES = {
--['<gameName>'] = {tones},
['DEFAULT'] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, 
['FIRETRUK'] = { 12, 13, 14, 11 }, 
['AMBULAN'] = { 1, 2, 3, 4, 11 }, 
['LGUARD'] = { 1, 2, 3, 4, 11 },
}



--[[
EXAMPLES BELOW: DELETE ME 
----------------------------------------------------------------------------------------
--Example B: MAXIMIZE LEO Tones: operate maximizing avaliable tones for LEOs.
['DEFAULT'] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 } 		--TouchMaster Delta Example: 1 - Airhorn, 2 - Wail, 3 - Yelp, 4 - Priority, 5 - Futura, 6 - Hetro, 7 - Sweep-1[Wail-Yelp], 8 - Sweep-2[Priority-Futura], 9 - Whine Down, 10 - Hi-Low
['FIRETRUK'] = { 12, 13, 14, 11 } 						--Shared Fire Truck Audio (12 - Firetruck Airhorn, 13 - Firetruck Wail, 14 - Firetruck Yelp, 11 - Powercall)
['AMBULANCE'] = { 1, 2, 3, 4, 5, 11 } 					--Ambulance 1 w/ department 1 audio (1 - Airhorn, 2 - Wail, 3 - Yelp, 4 - Priority, 5 - Sweep Mode, 11 - Powercall)

----------------------------------------------------------------------------------------
--Example C: Two Department Operation w/ Fire Rescue
['DEFAULT'] = { 1, 2, 3, 4, 5 } 		--Fallback for any model that isn't listed below.
['PD1'] = { 1, 2, 3, 4, 5 } 			--Department 1: Example: Whelen 295 Siren
['PD2'] = { 1, 2, 3, 4, 5 } 				--1 - 295 Airhorn, 2 - 295 Wail, 3 - 295 Yelp, 4 - 295 Priority, 5 - 295 Sweep Mode (Custom made wav with yelp + priority)
['PD3'] = { 1, 2, 3, 4, 5 } 				
['PD4'] = { 1, 2, 3, 4, 5 } 				
['PD5'] = { 1, 2, 3, 4, 5 } 				
['SO1'] = { 6, 7, 8, 9, 10 }			--Department 2: Example: FS Smart Siren
['SO2'] = { 6, 7, 8, 9, 10 }				--1 - FSS Airhorn, 2 - FSS Wail, 3 - FSS Yelp, 4 - FSS Priority, 5 - FSS Sweep Mode (Custom made wav with yelp + priority)
['SO3'] = { 6, 7, 8, 9, 10 }
['SO4'] = { 6, 7, 8, 9, 10 }
['SO5'] = { 6, 7, 8, 9, 10 }
['FIRETRUK'] = { 12, 13, 14, 11 } 		--Shared Fire Truck Audio (12 - Firetruck Airhorn, 13 - Firetruck Wail, 14 - Firetruck Yelp, 11 - Powercall)
['AMBULANCE1'] = { 1, 2, 3, 4, 5, 11 } 	--Ambulance 1 w/ department 1 audio (1 - 295 Airhorn, 2 - 295 Wail, 3 - 295 Yelp, 4 - 295 Priority, 5 - 295 Sweep Mode, 11 - Powercall)
['AMBULANCE2'] = { 6, 7, 8, 9, 10, 11 } --Ambulance 2 w/ department 2 audio (1 - FSS Airhorn, 2 - FSS Wail, 3 - FSS Yelp, 4 - FSS Priority, 5 - FSS Sweep Mode, 11 - Powercall)

----------------------------------------------------------------------------------------
--Example D: Three Department Operation w/ Shared Airhorn + Fire Rescue
['DEFAULT'] = { 1, 2, 3, 4 } 		--Fallback for any model that isn't listed below.
['PD1'] = { 1, 2, 3, 4 }			--Department 1: Example: Whelen 295 Siren
['PD2'] = { 1, 2, 3, 4 }				--1 - Shared Airhorn, 2 - 295 Wail, 3 - 295 Yelp, 4 - 295 Priority
['PD3'] = { 1, 2, 3, 4 }
['PD4'] = { 1, 2, 3, 4 }
['PD5'] = { 1, 2, 3, 4 }
['SO1'] = { 1, 5, 6, 7 }			--Department 2: Example: FS Smart Siren
['SO2'] = { 1, 5, 6, 7 }				--1 - Shared Airhorn, 5 - FSS Wail, 6 - FSS Yelp, 7 - FSS Priority
['SO3'] = { 1, 5, 6, 7 }
['SO4'] = { 1, 5, 6, 7 }
['SO5'] = { 1, 5, 6, 7 }
['HP1'] = { 1, 8, 9, 10 }			--Department 3: Example: TouchMaster Delta
['HP2'] = { 1, 8, 9, 10 }				--1 - Shared Airhorn, 8 - TMD Wail, 9 - TMD Yelp, 10 - TMD Priority
['HP3'] = { 1, 8, 9, 10 }
['HP4'] = { 1, 8, 9, 10 }
['HP5'] = { 1, 8, 9, 10 }
['FIRETRUK'] = { 12, 13, 14, 11 } 		--Shared Fire Truck Audio (12 - Firetruck Airhorn, 13 - Firetruck Wail, 14 - Firetruck Yelp, 11 - Powercall)
['AMBULANCE1'] = { 1, 2, 3, 4, 5, 11 } 	--Ambulance 1 w/ department 1 audio (1 - Shared Airhorn, 2 - 295 Wail, 3 - 295 Yelp, 4 - 295 Priority, 11 - Powercall)
['AMBULANCE2'] = { 6, 7, 8, 9, 10, 11 } --Ambulance 2 w/ department 2 audio (1 - Shared Airhorn, 5 - FSS Wail, 6 - FSS Yelp, 7 - FSS Priority, 11 - Powercall)
['AMBULANCE3'] = { 6, 7, 8, 9, 10, 11 } --Ambulance 3 w/ department 3 audio (1 - Shared Airhorn, 8 - TMD Wail, 9 - TMD Yelp, 10 - TMD Priority, 11 - Powercall)
]]
