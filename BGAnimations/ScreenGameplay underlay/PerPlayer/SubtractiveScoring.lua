local player = ...
local pn = ToEnumShortString(player)
local p = tonumber(player:sub(-1))
local mods = SL[pn].ActiveModifiers

-- Deal with Score Pace in a different lua because it's calculated every x measures instead of on JudgmentMessageCommand
if mods.SubtractiveScoring == "Off" or mods.SubtractiveScoring == "Score Pace" then return end 

-- 0.7.4 now includes "Full Subtractive" and "Predicted Score"
-- 0.7.6 now includes "Score Pace" and EX score subtractive (oh dear)
-- 0.7.6.1 has overhauled the subtractive scoring system to not use scripts to get dance points, but instead start at 0 and keep counting up

-- Subtractive
-- "Original" will count your <second judgment> up to 10, and then tell you how far away from 100% you are after that
-- "Full Subtractive" will do what Original does, but not count your excellents
-- "Predicted Score" will do the reverse of subtractive and just tell you what score you will get if you quad the rest
-- "Score Pace" which predicts your score based on your pace. Code currently resides in SubtractiveScoringPace.lua

-- original table, deprecated because we are now using max dp - lost dp to calculate the diff
--local dpdiff = {
--	-- numbers above 10 actually don't matter here
--	-- used to calculate dp difference for original subtractive scoring (-1 to -10)
--	ITG =       {W1 = 0, W2 = 1, W3 = 3, W4 = 5, W5 = 10, Miss = 17, HitMine = 6, Held = 0, LetGo = 5},
--	Waterfall = {W1 = 0, W2 = 1, W3 = 4, W4 = 7, W5 = 10, Miss = 10, HitMine = 3, Held = 0, LetGo = 6},
--}

local adddp = {
	-- used to calculate total dance points
	ITG =       {W1 = 5, 	W2 = 4, W3 = 2, W4 = 0, W5 = -6, 		Miss = -12, Held = 5, LetGo = 0, MissedHold = 0, HitMine = -6, 	AvoidMine = 0},
	Waterfall = {W1 = 10, 	W2 = 9, W3 = 6, W4 = 3, W5 = 0, 		Miss = 0, 	Held = 6, LetGo = 0, MissedHold = 0, HitMine = -3, 	AvoidMine = 0},
	EX = 		{W1 = 3.5, 	W2 = 3, W3 = 2, W4 = 1, W5 = 0, W6 = 0, Miss = 0, 	Held = 1, LetGo = 0, MissedHold = 0, HitMine = -1, 	AvoidMine = 0}, 
	-- EX has "W6" because of 2 fantastic windows + way offs
}

local losedp = {
	-- How much dp you lose based on what kind of note it is 
	-- Waterfall originally had W5 (wayoff) as -10 and not -11. Is that correct?
	ITG =       {W1 = 0, 	W2 = 1, 	W3 = 3, 	W4 = 5, 	W5 = 11, 			Miss = 17, 	Held = 0, LetGo = 5, MissedHold = 5, HitMine = 6, AvoidMine = 0},
	Waterfall = {W1 = 0, 	W2 = 1, 	W3 = 4, 	W4 = 7, 	W5 = 10, 			Miss = 10, 	Held = 0, LetGo = 6, MissedHold = 6, HitMine = 3, AvoidMine = 0}, 
	EX = 		{W1 = 0, 	W2 = 0.5, 	W3 = 1.5, 	W4 = 2.5, 	W5 = 3.5, W6 = 3.5, Miss = 3.5, Held = 0, LetGo = 1, MissedHold = 1, HitMine = 1, AvoidMine = 0}, 
}

local useitg = mods.SimulateITGEnv
local subType = mods.SubtractiveScoring
local subEnv = mods.SubtractiveEnvironment

if subEnv == "Default" then 
	if mods.EXScoring then 
		subEnv = "EX"
	else 
		subEnv = useitg and "ITG" or "Waterfall" 	
	end
end

local mode = (not useitg) and "Waterfall" or "ITG"
local othermode = (useitg) and "Waterfall" or "ITG"

local maxdp
local curmaxdp
local curdp
local dplost

-- Amount of things that have passed, for WhoIsCurrentlyWinning.lua
local things = 0

local alive = true

-- which font should we use for the BitmapText actor?
-- [TODO] this font will probably not be " wendy " in the end. sorry wendy :(
local font = "_wendy small"

-- -----------------------------------------------------------------------

-- the BitmapText actor
local bmt = LoadFont(font)

bmt.InitCommand=function(self)
	self:diffuse(color("#ff55cc"))
	self:zoom(0.35):shadowlength(1):horizalign(center)

	local width = GetNotefieldWidth()
	local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
	-- mirror image of MeasureCounter.lua
	self:xy( GetNotefieldX(player) + (width/NumColumns), _screen.cy - 55 )
	self:horizalign(left)
	-- nudge slightly left (15% of the width of the bitmaptext when set to "100.00%")
	self:settext("100.00%"):addx( -self:GetWidth()*self:GetZoom() * 0.15 )
	self:settext("")
end


bmt.OnCommand=function(self)
	-- for some reason pss:GetPossibleDancePoints() showed up as 0 sometimes. so calculate WF manually
	steps = (not GAMESTATE:IsCourseMode()) and GAMESTATE:GetCurrentSteps(player)
			or GAMESTATE:GetCurrentTrail(player)
	local iscourse = (steps.GetAllSongs == nil)
	local radar = steps:GetRadarValues((not iscourse) and player or nil)
	local weights = adddp[subEnv]
	local totalholdjudgments = radar:GetValue("RadarCategory_Holds") + radar:GetValue("RadarCategory_Rolls")
	local totaltapjudgments = radar:GetValue("RadarCategory_TapsAndHolds")

	maxdp 		=  totalholdjudgments * weights.Held + totaltapjudgments * weights.W1
	curmaxdp	= maxdp
	curdp		= 0
	dplost		= 0
end

local combotype = 1
local maxcombotype = useitg and 4 or 3
local threshold = (subType == "Full" or subType == "Predicted") and 0 or 10 

bmt.JudgmentMessageCommand=function(self, params)
	if player == params.Player and alive then
		-- Colored subtractive mode
		if mods.SubtractiveExtra then
			if params.TapNoteScore and (not params.HoldNoteScore) and params.TapNoteScore ~= "TapNoteScore_AvoidMine" and
			params.TapNoteScore ~= "TapNoteScore_HitMine" and params.TapNoteScore ~= "TapNoteScore_Miss" then
				local w = DetermineTimingWindow(params.TapNoteOffset, othermode)
				if w > 1 then
					combotype = math.max(combotype,w)
				end
			end
			
			if params.TapNoteScore and params.TapNoteScore == "TapNoteScore_Miss" then
				combotype = 6
			end
			
			if combotype <= maxcombotype then
				self:diffuse(SL.JudgmentColors[othermode][combotype])
			else
				self:diffuse(1,1,1,1)
			end	
		end
		
		-- get the environment values to use
		local add_table = adddp[subEnv]
		local lose_table = losedp[subEnv]
		
		-- Figure out which kind of judgment it is
		tns = ToEnumShortString(params.TapNoteScore)
		hns = params.HoldNoteScore and ToEnumShortString(params.HoldNoteScore)
		local judgment = hns or tns
			
		-- if it's a tap note, find out what the timing window is 
		if not hns and params.TapNoteOffset and (judgment == "W1" or judgment == "W2" or judgment == "W3" or judgment == "W4" or judgment == "W5") then
			-- EX score has a different score weight for blue and white fantastics. push everything out to W6
			if subEnv == "EX" then			
				judgment = DetermineTimingWindow(params.TapNoteOffset, "ITG")
				if judgment > 1 then judgment = judgment + 1 end
				if judgment == 1 and math.abs(params.TapNoteOffset) > 0.015 then judgment = 2 end
				judgment = "W"..judgment
			elseif subEnv == "ITG" then	
				judgment = "W"..DetermineTimingWindow(params.TapNoteOffset, "ITG")
			end
		end
		
		-- Find out dance points to add, subtract, and total possible/lost
		local dp_add 	= add_table[judgment]
		local dp_minus	= lose_table[judgment]
		
		dplost 		= dplost + dp_minus
		curmaxdp 	= curmaxdp - dp_minus
		curdp 		= curdp + dp_add
		
		-- for revamped WhoIsCurrentlyWinning.lua
		-- This gets the values for the subtractive environment, which won't be correct
		-- if they are not using default. Fix at some point
		-- Waterfall 0.7.7
		things = things + 1
		if #GAMESTATE:GetHumanPlayers() == 2 then 
			MESSAGEMAN:Broadcast("CurrentlyWinning", {
				p=p,
				things=things,
				curmaxdp=curmaxdp,
				curdp=curdp})
		 end


		if dplost == 0 then return end
		local text = (maxdp-dplost) / maxdp
		if text < 0 then text = 0 end
		text = math.floor(text*10000)/100
		if subType == "Predicted" then 
			self:settext(string.format("%.2f%%",text))
		end
		if subType == "Original" and (dplost/lose_table.W2) <= 10 then 
			self:settext("-" .. tostring(dplost/lose_table.W2))
		end
		if subType == "Full" or (subType == "Original" and (dplost/lose_table.W2) > 10) then 
			self:settext("-"..string.format("%.2f%%",100-text))
		end
			
	end
end	

bmt.WFFailedMessageCommand=function(self, params)
	if params.pn == p and subEnv == "Waterfall" then
		alive = false
		
		local dancepoints
		if subEnv == "EX" then
			dancepoints = WF.GetEXPercentDP(player)*100
		else
			local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
			dancepoints = pss:GetPercentDancePoints()*100
		end

		if subType == "Predicted" then 
			self:settext(string.format("%.2f%%",dancepoints))
			return
		end
		if subType == "Original" or subType == "Full" then 
			self:settext("-"..string.format("%.2f%%",100-dancepoints))
			return
		end
			
	end
end

bmt.ITGFailedMessageCommand=function(self, params)
	if params.pn == p and (subEnv == "ITG" or subEnv == "EX") then
		alive = false
		
		local dancepoints
		if subEnv == "EX" then
			dancepoints = WF.GetEXPercentDP(player)*100
		else
			dancepoints = WF.GetITGPercentDP(player, WF.GetITGMaxDP(player))*100
		end
		
		if subType == "Predicted" then 
			self:settext(string.format("%.2f%%",dancepoints))
			return
		end
		if subType == "Original" or subType == "Full" then 
			self:settext("-"..string.format("%.2f%%",100-dancepoints))
			return
		end
	end
end


return bmt
