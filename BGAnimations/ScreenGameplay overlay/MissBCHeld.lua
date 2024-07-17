-- Each time a judgment occurs during gameplay, the engine broadcasts some relevant data
-- as a key/value table that themeside Lua can listen for via JudgmentMessageCommand()
--
-- The details of *what* gets broadcast is complicated and not documented anywhere I've found,
-- but you can grep the src for "Judgment" (quotes included) to get a sense of what gets sent
-- to Lua in different circumstances.
--
-- This file, PerColumnJudgmentTracking.lua exists so that ScreenEvaluation can have a pane
-- that displays a per-column judgment breakdown.
--
-- We have a local table, judgments, that has as many sub-tables as the current game has panels
-- per player (4 for dance-single, 8 for dance-double, 5 for pump-single, etc.)
-- and each of those sub-tables stores the number of judgments that occur during gameplay on
-- that particular panel.
--
-- This doesn't override or recreate the engine's judgment system in any way. It just allows
-- transient judgment data to persist beyond ScreenGameplay.
------------------------------------------------------------

-- changing this to be in the format of just
-- storage.miss_bcheld = { l, d, u, r, etc }
local players = GAMESTATE:GetHumanPlayers()
local missbcheld = {}

--I don't see why held misses shouldn't be recorded all the time so I'm enabling it by default
--local track_missbcheld = false

-- Track held misses only until death. 
-- It will be accurate except in the condition: ITG environment, ITG failing, continuing to play before WF failing. 
-- But that will be rare so whatever
local alive = {}
local env = {}

for player in ivalues(players) do
	--track_missbcheld = track_missbcheld or SL[ToEnumShortString(player)].ActiveModifiers.MissBecauseHeld
	alive[tonumber(player:sub(-1))] = true	
	env[tonumber(player:sub(-1))] = SL[ToEnumShortString(player)].ActiveModifiers.SimulateITGEnv and "ITG" or "Waterfall"
	
	missbcheld[tonumber(player:sub(-1))] = {0,0,0,0,0,0,0,0,0,0}
end

local actor = Def.Actor{
	OffCommand=function(self)
		for player in ivalues(players) do
			local storage = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1]
			storage.miss_bcheld = missbcheld[tonumber(player:sub(-1))]
		end
	end
}

local buttons = {
	dance = { "Left", "Down", "Up", "Right" },
	pump = { "DownLeft", "UpLeft", "Center", "UpRight", "DownRight" }
}

local current_game = GAMESTATE:GetCurrentGame():GetName()
local held = {}

-- initialize to handle both players, regardless of whether both are actually joined.
-- the engine's InputCallback gives you ALL input, so even if only P1 is joined, the
-- InputCallback will report someone spamming input on P2 as valid events, so we have
-- to ensure that doesn't cause Lua errors here
for player in ivalues({PLAYER_1, PLAYER_2}) do
	held[player] = {}

	-- initialize all buttons available to this game for this player to be "not held"
	for button in ivalues(buttons[current_game]) do
		held[player][button] = false
	end
end



local InputHandler = function(event)
	-- if any of these, don't attempt to handle input
	if not event.PlayerNumber or not event.button then return false end

	if event.type == "InputEventType_FirstPress" then
		held[event.PlayerNumber][event.button] = true
	elseif event.type == "InputEventType_Release" then
		held[event.PlayerNumber][event.button] = false
	end
end

actor.OnCommand=function(self) SCREENMAN:GetTopScreen():AddInputCallback( InputHandler ) end
actor.JudgmentMessageCommand=function(self, params)
	if (params.Notes) and (params.TapNoteScore == "TapNoteScore_Miss") then
		for col,tapnote in pairs(params.Notes) do
			-- only concerned with miss bc held here now
			local p = tonumber(params.Player:sub(-1))
			
			-- check alive state first
			if alive[p] then 			
				if held[params.Player][ buttons[current_game][col] ] then
					missbcheld[p][col] = missbcheld[p][col] + 1
				end
			end
		end
	end
end

actor.ITGFailedMessageCommand=function(self,params)
	local p = tonumber(params.pn)
	if env[p] == "ITG" then alive[p] = false end	
end

actor.WFFailedMessageCommand=function(self,params)
	--SM(params)
	local p = tonumber(params.pn)
	if env[p] == "Waterfall" then alive[p] = false end	
end


return actor