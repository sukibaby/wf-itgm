local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers
	
if mods.HideLifebar then return end

local useitg = mods.SimulateITGEnv

local lifemeter_actor = Def.ActorFrame{}


-- conditionally load the "normal" lifebars, or itg lifebar if using "simulate itg" option
if mods.LifeMeterType == "Surround" then
--	-- create a bar for all 3
	if not useitg then
		for i = 1, #WF.LifeBarNames do
			-- I hope nobody ever uses this
			lifemeter_actor[#lifemeter_actor+1] = LoadActor("./SurroundStandard.lua", {player=player, index=i})
		end
		else
			lifemeter_actor[#lifemeter_actor+1] = LoadActor("./SurroundITG.lua", player)
	end
else
if not useitg then
	-- create a bar for all 3
	for i = 1, #WF.LifeBarNames do
		lifemeter_actor[#lifemeter_actor+1] = LoadActor("./Standard.lua", {player=player, index=i})
	end
else
	lifemeter_actor[#lifemeter_actor+1] = LoadActor("./ITG.lua", player)
end

end


return lifemeter_actor