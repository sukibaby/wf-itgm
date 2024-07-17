local player = ...
local pn = ToEnumShortString(player)
local p = tonumber(player:sub(-1))
local mods = SL[pn].ActiveModifiers
local useitg = mods.SimulateITGEnv

local PlayerState = GAMESTATE:GetPlayerState(player)

if mods.SubtractiveScoring ~= "Score Pace" then return end

-- Pace option introduced in Waterfall 0.7.6
-- This shows the score you are on pace to get rather than "if you quad the rest"
-- Possibly useful in marathons

-- I put this in a separate file because it's sorta a different function to traditional subtractive scoring
-- I'll maybe merge it at some point (probably never)

local alive = true

-- Don't show up at the beginning because the number is prety useless with such a small sample size
-- Start displaying after 100 dance points
-- which is 20 fantastics or masterfuls
local display = false
local startDisplay = useitg and 100 or 200

local updateEvery = 2 -- How many measures wait to update. 1 seems like too often


local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local font = "_wendy small"
local prevMeasure = 0
local othermode = useitg and "Waterfall" or "ITG"
local combotype = 1
local maxcombotype = useitg and 4 or 3

local bmt = LoadFont(font)

local Update = function(self)	

	if alive then
		--Update once every x measures
		local currMeasure = (math.floor(PlayerState:GetSongPosition():GetSongBeatVisible()))/(updateEvery*4)
		
		-- If a new measure has occurred
		if math.floor(currMeasure) > prevMeasure then
			prevMeasure = math.floor(currMeasure)
			local dp_poss = (useitg) and WF.ITGMaxDP[p] or pss:GetPossibleDancePoints()
			local dp_currPoss = (useitg) and WF.ITGCurMaxDP[p] or pss:GetCurrentPossibleDancePoints()
			local dp = (useitg) and WF.ITGDP[p] or pss:GetActualDancePoints()
			
			if dp_currPoss >= startDisplay then
				display = true
			end
			
			if display then 
				local pace = dp/dp_currPoss*10000/100
				bmt:settext(string.format("%.2f", pace))
			end
		end
	end
end

local af = Def.ActorFrame{
	InitCommand=function(self)
		self:queuecommand("SetUpdate")
		if not mods.ColoredSubtractive then 
			self:diffuse(color("#ff55cc"))
		end
	end,
	SetUpdateCommand=function(self) self:SetUpdateFunction( Update ) end,
	JudgmentMessageCommand=function(self, params)
		if player == params.Player and alive and mods.SubtractiveExtra then	
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
	end	
}

af[#af+1] = LoadFont(font)..{
	InitCommand=function(self)
		bmt = self
		self:zoom(0.35):shadowlength(1):horizalign(center)

		local width = GetNotefieldWidth()
		local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
		-- mirror image of MeasureCounter.lua
		self:xy( GetNotefieldX(player) + (width/NumColumns), _screen.cy - 55 )
		self:horizalign(left)
		-- nudge slightly left (15% of the width of the bitmaptext when set to "100.00%")
		self:settext("100.00%"):addx( -self:GetWidth()*self:GetZoom() * 0.15 )
		self:settext("")
	end,
	WFFailedMessageCommand=function(self, params)
		if params.pn == p and not useitg then
			alive = false

			dance_points = pss:GetPercentDancePoints()
			
			percent = string.format("%.2f%%", dance_points*100)
			
			self:settext(percent)
				
		end
	end,
	ITGFailedMessageCommand=function(self, params)
		if params.pn == p and useitg then
			alive = false
	
			dance_points = WF.GetITGPercentDP(player, itgmaxdp)
			
			percent = string.format("%.2f%%", dance_points*100)
			
			self:settext(percent)
		end
	end
}

return af