local player = ...
local pn = ToEnumShortString(player)
local pnum = tonumber(player:sub(-1))
local mods = SL[pn].ActiveModifiers

local itg = mods.SimulateITGEnv

-- This is used in Sounds/ScreenGameplay Music.lua
-- We track pass or fail here for the purpose of playing a different sound
-- because doing it to track WF/ITG pass/fail is troublesome in the lua directly
-- probably I'm just too stupid to figure it out 

GAMESTATE:Env()["Fail" .. pn] = false -- Global variable

local af = Def.ActorFrame{
	ITGFailedMessageCommand=function(self,params)
		if params.pn == pnum and itg then
			GAMESTATE:Env()["Fail" .. pn] = true
		end
	end,
	WFFailedMessageCommand=function(self,params)
		if params.pn == pnum and not itg then
			GAMESTATE:Env()["Fail" .. pn] = true
		end
	end,
}

return af
