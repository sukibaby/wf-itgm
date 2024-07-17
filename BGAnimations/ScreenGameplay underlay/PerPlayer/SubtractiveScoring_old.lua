local player = ...
local pn = ToEnumShortString(player)
local p = tonumber(player:sub(-1))
local mods = SL[pn].ActiveModifiers

-- 0.7.4 now includes "Full Subtractive" and "Predicted Score"
-- 0.7.6 now includes "Score Pace" and EX score subtractive (oh dear)

-- Subtractive
-- "Original" will count your excellents up to 10, and then tell you how far away from 100% you are 
-- "Full Subtractive" will do what Original does, but not count your excellents
-- "Predicted Score" will do the reverse of subtractive and just tell you what score you will get if you quad the rest
-- "Score Pace" which predicts your score based on your pace. Code currently resides in SubtractiveScoringPace.lua

local subtractiveType = mods.SubtractiveScoring

-- Deal with Score Pace in a different lua because it's caculated every x measures instead of on JudgmentMessageCommand
if subtractiveType == "Off" or subtractiveType == "Score Pace" then return end 

local ExSubtractive = subtractiveType == "EX Score" and true or false

local useitg = mods.SimulateITGEnv
local mode = (not useitg) and "Waterfall" or "ITG"
local othermode = (useitg) and "Waterfall" or "ITG"

local itgmaxdp
if useitg then
	itgmaxdp = WF.GetITGMaxDP(player)
end

-- Eventually I'll have pb/rival comparisons

-- To get machine and personal best
local GetSongAndSteps = function(player)
	local SongOrCourse = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()
	local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
	return SongOrCourse, StepsOrTrail
end

local GetHighScore = function(SongOrCourse, StepsOrTrail, pn, itg)
	-- nil pn means machine score
	-- if we don't have everything we need, return empty strings
	if not (SongOrCourse and StepsOrTrail) then return "","" end
	if (pn) and (not WF.PlayerProfileStats[pn]) then return "","" end

	local score
	local rate = RateFromNumber(SL.Global.ActiveModifiers.MusicRate)
	local iscourse = (SongOrCourse.GetAllSteps == nil)
	local hash = (not iscourse) and HashCacheEntry(StepsOrTrail)
	local stats = WF.FindProfileSongStatsFromSteps(SongOrCourse, StepsOrTrail,
		rate, hash, pn)

	if stats then
		if pn then
			score = ((not itg) and stats.BestPercentDP or stats.BestPercentDP_ITG)/100
		else
			local item = stats["HighScoreList"..(itg and "_ITG" or "")][1]
			if item then
				score = item.PercentDP/100
			else
				score = 0.00
			end
		end
	else
		score = 0.00
	end

	return score
end

local SongOrCourse, StepsOrTrail = GetSongAndSteps(player)

local alive = true
-------------------------------------------------------------------------

local metrics = SL.Metrics.Waterfall

local dpdiff = {
	-- numbers above 10 actually don't matter here
	-- This is to calculate dp difference for original subtractive scoring
	ITG =       {W1 = 0, W2 = 1, W3 = 3, W4 = 5, W5 = 10, Miss = 17, HitMine = 6, Held = 0, LetGo = 5},
	Waterfall = {W1 = 0, W2 = 1, W3 = 4, W4 = 7, W5 = 10, Miss = 10, HitMine = 3, Held = 0, LetGo = 6},
	EX = 		{W1 = 0, W2 = 1, W3 = 3, W4 = 5, W5 = 7, W6 = 7, Miss = 7, Held = 0, LetGo = 2, HitMine = 2, MissedHold = 2, AvoidMine = 0}, 
}

local adddp = {
	-- scoring
	ITG =       {W1 = 5, W2 = 4, W3 = 2, W4 = 0, W5 = -6, Miss = -12, HitMine = -6, Held = 5, LetGo = 0},
	Waterfall = {W1 = 0, W2 = 1, W3 = 4, W4 = 7, W5 = 10, Miss = 10, HitMine = 3, Held = 0, LetGo = 6},
	EX = 		{W1 = 3.5, W2 = 3, W3 = 2, W4 = 1, W5 = 0, W6 = 0, Miss = 0, Held = 1, LetGo = 0, HitMine = -1, MissedHold = 0, AvoidMine = 0}, -- we have W6 now because of 2 fantastic windows + way offs
}

local losedp = {
	-- Using new (simpler?) system because old one didn't work properly for EX scoring. W6 now because two fantastic windows + way off
	-- Add WF/ITG at some point and use this system
	EX = 		{W1 = 0, W2 = 0.5, W3 = 1.5, W4 = 2.5, W5 = 3.5, W6 = 3.5, Miss = 3.5, Held = 0, LetGo = 1, HitMine = 1, MissedHold = 1, AvoidMine = 0}, 
}

local dplost = 0

local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

-- which font should we use for the BitmapText actor?
-- [TODO] this font will probably not be " wendy " in the end. sorry wendy :(
local font = "_wendy small"

-- -----------------------------------------------------------------------

-- the BitmapText actor
local bmt = LoadFont(font)

bmt.InitCommand=function(self)
	self:diffuse(color("#ff55cc"))
	self:zoom(0.35):shadowlength(1):horizalign(center)

	if ExSubtractive then self:diffuse(SL.JudgmentColors.ITG[1]) end 
	local width = GetNotefieldWidth()
	local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
	-- mirror image of MeasureCounter.lua
	self:xy( GetNotefieldX(player) + (width/NumColumns), _screen.cy - 55 )
	self:horizalign(left)
	-- nudge slightly left (15% of the width of the bitmaptext when set to "100.00%")
	self:settext("100.00%"):addx( -self:GetWidth()*self:GetZoom() * 0.15 )
	self:settext("")
end


local combotype = 1
local maxcombotype = useitg and 4 or 3

local threshold = (subtractiveType == "Full" or subtractiveType == "Predicted") and 0 or 10 

local curMaxEXDP = function(player)
	local notes = 0
	local holds = 0
	local mines = 0
	local weights = WF.EXScoreWeights
	local judgeTable = WF.EXJudgments
	local judgeCounts = WF.GetEXJudgmentCounts(player)	
	
	for i=1,7 do
		notes = notes + judgeCounts[i]
	end	
	
	holds	= judgeCounts[8]
	mines	= judgeCounts[10]
	
	maxexdp = notes * weights[judgeTable.FantasticPlus] 
		+ holds * weights[judgeTable.Held] 
		+ mines * weights[judgeTable.Mine] 
	return maxexdp
end

-- This is temporary while I fix up everything
local ex_maxdp 		= WF.GetEXMaxDP(player)
local ex_curmaxdp 	= ex_maxdp
local ex_curdp 		= 0
local ex_dplost 	= 0

local ex_environment = "EX"



bmt.JudgmentMessageCommand=function(self, params)
	if player == params.Player and alive then
		-- Deal with ex scoring subtractive here because I'm running low on time
		-- I'd rather create a proper function for this and completely overhaul
		-- how subtractive scoring works
		-- but that's a problem for another day (probably never)
		-- Zarzob
		if ExSubtractive then	
			-- TODO: Get course mode working too
			
			-- get which environments to subtract from
			local add_table = adddp.EX
			local lose_table = losedp.EX						
			local diff_table = dpdiff.EX						
			local scoreTable = WF.EXScoreWeights
			local weights = WF.EXJudgments
			
			-- Figure out which kind of judgment it is
			tns = ToEnumShortString(params.TapNoteScore)
			hns = params.HoldNoteScore and ToEnumShortString(params.HoldNoteScore)
			local judgment = hns or tns
			
			-- Convert tap notes into ITG FA+ (15ms) judgments
			if not hns and params.TapNoteOffset and (judgment == "W1" or judgment == "W2" or judgment == "W3" or judgment == "W4" or judgment == "W5") then
				judgment = DetermineTimingWindow(params.TapNoteOffset, "ITG")
				if judgment > 1 then judgment = judgment + 1 end
				if judgment == 1 and math.abs(params.TapNoteOffset) > 0.015 then judgment = 2 end
				judgment = "W"..judgment
			end
			
			-- Find out dance points to add, subtract, and total possible/lost
			local dp_add 	= add_table[judgment]
			local dp_minus	= lose_table[judgment]
			
			ex_dplost 		= ex_dplost + dp_minus
			ex_curmaxdp 	= ex_curmaxdp - dp_minus
			ex_curdp 		= ex_curdp + dp_add

			
			
			local predictedscore = math.floor(((ex_maxdp-ex_dplost) / ex_maxdp)*10000)/100
			local subtractedscore = 100-math.floor(((ex_maxdp-ex_dplost) / ex_maxdp)*10000)/100
			--if dplost ~= 0 then 
			SM(ex_maxdp .. " " .. ex_dplost)
				self:settext( string.format("%.2f%%",subtractedscore))
			--end
			
			return
		end
		-- Colored Subtractive logic
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
	
		tns = ToEnumShortString(params.TapNoteScore)
		-- compensate for itg
		if useitg and params.TapNoteOffset and (tns == "W1" or tns == "W2" or tns == "W3" or tns == "W4" or tns == "W5") then
			tns = "W"..DetermineTimingWindow(params.TapNoteOffset, "ITG")
		end
		hns = params.HoldNoteScore and ToEnumShortString(params.HoldNoteScore)
		
		local judgment = hns or tns
		if not dpdiff[mode][judgment] then return end

		dplost = dplost + dpdiff[mode][judgment]
		
		if dplost == 0 then return end
		
		if dplost < threshold then
			self:settext(string.format("-%d", dplost))
		else
			local possible_dp = (not useitg) and pss:GetPossibleDancePoints() or WF.ITGMaxDP[p]
			local current_possible_dp = (not useitg) and pss:GetCurrentPossibleDancePoints() or WF.ITGCurMaxDP[p]

			-- max to prevent subtractive scoring reading more than -100%
			local dp = (not useitg) and pss:GetActualDancePoints() or WF.ITGDP[p]
			local actual_dp = math.max(dp, 0)

			local score = current_possible_dp - actual_dp
			score = math.floor(((possible_dp - score) / possible_dp) * 10000) / 100
			
			-- specify percent away from 100%
			local scoretext = subtractiveType == "Predicted" and string.format("%.2f%%", score) or string.format("-%.2f%%", 100-score)

			self:settext(scoretext)
		end
	end
end

bmt.WFFailedMessageCommand=function(self, params)
	if params.pn == p and not useitg then
		alive = false
		
		dance_points = pss:GetPercentDancePoints()
		
		percent = subtractiveType == "Predicted" and string.format("%.2f%%", dance_points*100) or string.format("-%.2f%%", 100-(dance_points*100))
		
		self:settext(percent)
			
	end
end

bmt.ITGFailedMessageCommand=function(self, params)
	if params.pn == p and useitg then
		alive = false

		if ExSubtractive then
			local expercent = WF.GetEXScore(player)
			self:settext(expercent)
			return
		end
			
		dance_points = WF.GetITGPercentDP(player, itgmaxdp)

		percent = subtractiveType == "Predicted" and string.format("%.2f%%", dance_points*100) or string.format("-%.2f%%", 100-(dance_points*100))
		
		self:settext(percent)
	end
end


return bmt
