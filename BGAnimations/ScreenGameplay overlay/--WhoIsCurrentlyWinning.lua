-- This doesn't currently work properly. I'm going to revamp the way that scores are tracked in a future release and fix this at the same time


-- If both players are joined, change the opacity of their score BitmapText actors to
-- visually indicate who is winning at a given moment during gameplay.
------------------------------------------------------------

-- if there is only one player, don't bother
if #GAMESTATE:GetHumanPlayers() < 2 then return end

local steps = {}
-- If both players aren't playing the same chart, don't bother 
steps[1] = GAMESTATE:GetCurrentSteps(PLAYER_1)
steps[2] = GAMESTATE:GetCurrentSteps(PLAYER_2)
if steps[1] ~= steps[2] then return end 

--If both players do not have matching environments, we don't know what to compare, so don't bother 
local mods = {}
mods[1] = SL[ToEnumShortString(PLAYER_1)].ActiveModifiers
mods[2] = SL[ToEnumShortString(PLAYER_2)].ActiveModifiers

local env = {}
env[1] = mods[1].SimulateITGEnv and "ITG" or "Waterfall"
env[2] = mods[2].SimulateITGEnv and "ITG" or "Waterfall"

if mods[1].EXScoring then env[1] = "EX" end
if mods[2].EXScoring then env[2] = "EX" end


if env[1] ~= env[2] then return end

SM(env[1] .. " " .. env[2])
local p1_score, p2_score
local things = {}
local cur = {}

-- allow for HideScore, which outright removes score actors
local try_diffusealpha = function(af, alpha)
	if not af then return end	
	af:diffusealpha(alpha)
end

return Def.Actor{
	OnCommand=function(self)
		local underlay = SCREENMAN:GetTopScreen():GetChild("Underlay")
		p1_score = underlay:GetChild("P1Score")
		p2_score = underlay:GetChild("P2Score")
		
	end,
	--JudgmentMessageCommand=function(self) self:queuecommand("Winning") end,
	CurrentlyWinningMessageCommand=function(self, params)
		-- In the old version of this code, the number will flash on every JudgmentMessageCommand.
		-- This means that the losing player can hit an arrow a split second before the winning player
		-- and have a higher score for that split second until the other player hits the arrow.
		-- at RIP 12.1 this was very distracting and people ended up hiding the score.
		-- Therefore, we only want to compare the scores *after* both players have finished with each note/hold.

		-- The goal is to compare dance points for the currently selected environment, however
		-- the values are coming from SubtractiveScoring.lua, which take the dance points of the 
		-- subtractive environment. In most cases this will be correct but if the max dance points
		-- are different then it just won't do the comparison. Will fix it at some point.
		
		-- Also it just won't do anything if they have turned subtractive scoring off lol
		-- TODO Deal with dance point tracking in a different file 

		-- Waterfall Expanded 0.7.7
		
		things[params.p] = params.things -- Laziest naming ever lol
		
		cur[params.p] = params.curdp
		
		if things[1] ~= things[2] then return end -- Wait until both players have hit (or missed) each note

		-- calculate the percentage DP manually rather than use GetPercentDancePoints.
		-- That function rounds to the nearest .01%, which is inaccurate on long songs.
		--p1_dp = p1_pss:GetActualDancePoints() / p1_pss:GetPossibleDancePoints()
		--p2_dp = p2_pss:GetActualDancePoints() / p2_pss:GetPossibleDancePoints()
		-- No longer in use as of Waterfall Expanded 0.7.7 because this only compares Engine scores (Waterfall environment)
		SM(cur[1] .. " " .. cur[2])
		if cur[1] == cur[2] then
			try_diffusealpha(p1_score, 1)
			try_diffusealpha(p2_score, 1)
		elseif cur[1] > cur[2] then
			try_diffusealpha(p1_score, 1)
			try_diffusealpha(p2_score, 0.65)
		elseif cur[1] < cur[2] then
			try_diffusealpha(p1_score, 0.65)
			try_diffusealpha(p2_score, 1)
		end
	end
}
