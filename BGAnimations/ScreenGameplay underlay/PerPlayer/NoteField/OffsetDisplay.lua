local player = ...
local pn = tonumber(player:sub(-1))
local mods = SL["P"..pn].ActiveModifiers -- urgh why is pn not consistent through the whole theme lol

if not mods.OffsetDisplay then return end

local style = SL["P"..pn].ActiveModifiers.EarlyLate
local color = SL["P"..pn].ActiveModifiers.EarlyLateColor

local useitg = SL["P"..pn].ActiveModifiers.SimulateITGEnv
local env = (not useitg) and "Waterfall" or "ITG"

local elcolors = {{0,0.5,1,1},{1,0.5,1,1}} -- blue/pink

local threshold = 0
local thresholdmod = SL["P"..pn].ActiveModifiers.EarlyLateThreshold
local faplusmod = SL["P"..pn].ActiveModifiers.FAPlus
if thresholdmod == "FA+" then
    threshold = (faplusmod > 0) and faplusmod or 0
elseif thresholdmod == "None" then
    threshold = -1
end

local yposDash = 30 --position no longer changes based on location of measure counter
local ypos = (SL["P"..pn].ActiveModifiers.MeasureCounterUp) and 12 or 12

local fontScale = 0.96

--local judgewidthWF = {106,86,60,40,65,0,0,0}
local judgewidthWF = {106*fontScale,86*fontScale,60*fontScale,40*fontScale,65*fontScale,0,0,0}
local judgewidthITG = {95*fontScale,92*fontScale,62*fontScale,68*fontScale,72*fontScale,0,0,0}

if (useitg) and threshold == 0 then
    threshold = WF.ITGTimingWindows[WF.ITGJudgments.Fantastic]
elseif (not useitg) and threshold == 0.015 then
    -- this condition should not happen but might as well cover it here too
    threshold = 0
end

local text = LoadFont("_wendy small")..{
    Text = "",
    InitCommand = function(self)
        local reverse = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred"):UsingReverse()
        self:zoom(0.25)
        self:y((reverse and 1 or -1) * ypos)
    end,
    JudgmentMessageCommand = function(self, params)
        if params.Player ~= player then return end
        if params.TapNoteScore and (not params.HoldNoteScore) and params.TapNoteScore ~= "TapNoteScore_AvoidMine" and
        params.TapNoteScore ~= "TapNoteScore_HitMine" and params.TapNoteScore ~= "TapNoteScore_Miss" then
			self:finishtweening()
			local offsetms = params.TapNoteOffset * 1000
			self:settext(("%.2f"):format(offsetms).."ms")

			local w = tonumber(params.TapNoteScore:sub(-1))
			if useitg then w = DetermineTimingWindow(params.TapNoteOffset, "ITG") end
			self:diffuse(SL.JudgmentColors[env][w])
			
			-- self:x((params.Early and -1 or 1) * 40)
			self:diffusealpha(1)
			self:sleep(2)
			self:diffusealpha(0)
			
			self:visible(GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred"):Blind() == 0)
			
		elseif params.TapNoteScore == "TapNoteScore_Miss" then
			self:finishtweening()
			self:diffusealpha(0)
		end
    end
}

local af = Def.ActorFrame{
    InitCommand = function(self)
        self:xy(GetNotefieldX(player), _screen.cy + 5)
    end,
	UpdateBGFilterPositionMessageCommand=function(self, params)
		if params.Player == player then
			local p = SCREENMAN:GetTopScreen():GetChild("Player"..pn)
			if p then
				self:x(p:GetX())
			end
		end
	end,
	JudgementMessageCommand=function(self,params)
	-- Fun mod stuff
	local TNO = params.TapNoteOffset and params.TapNoteOffset or 0
	if mods.JudgementTilt then
		self:rotationz(TNO * 300 * mods.JudgementTiltMultiplier)
	end
end
}

af[#af+1] = text

return af
