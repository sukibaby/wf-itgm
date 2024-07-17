local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers

-- As of 0.7.6, now using a slider for background filter under ScreenDarken

-- if no BackgroundFilter is necessary, it's safe to bail now
--if mods.BackgroundFilter == "Off" then return end
if mods.ScreenDarken  == 0 then return end


--local FilterAlpha = {
--	Dark = 0.5,
--	Darker = 0.75,
--	Darkest = 0.95
--}

local af = Def.ActorFrame {}

af[#af+1] = Def.Quad{
	InitCommand=function(self)
		self:xy(GetNotefieldX(player), _screen.cy+80 )
			:diffuse(Color.Black)
			--:diffusealpha( FilterAlpha[mods.BackgroundFilter] or 0 )
			:diffusealpha(mods.ScreenDarken)
			:zoomto( GetNotefieldWidth(), _screen.h )
			--:valign(0)
	end,
	OffCommand=function(self) self:queuecommand("ComboFlash") end,
	ComboFlashCommand=function(self)
		local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
		local FlashColor = nil

		local stepcount = GAMESTATE:GetCurrentSteps(player):GetRadarValues(player):GetValue("RadarCategory_TapsAndHolds")
		local totaljudgments = pss:GetTapNoteScores("TapNoteScore_W1") + pss:GetTapNoteScores("TapNoteScore_W2") +
			pss:GetTapNoteScores("TapNoteScore_W3") + pss:GetTapNoteScores("TapNoteScore_W4") +
			pss:GetTapNoteScores("TapNoteScore_W5") + pss:GetTapNoteScores("TapNoteScore_Miss")
		
		if totaljudgments < stepcount then return end

		if not mods.SimulateITGEnv then
			local WorstAcceptableFC = SL.Preferences.Waterfall.MinTNSToHideNotes:gsub("TapNoteScore_W", "")

			for i=1, tonumber(WorstAcceptableFC) do
				if pss:FullComboOfScore("TapNoteScore_W"..i) then
					FlashColor = SL.JudgmentColors.Waterfall[i]
					break
				end
			end
		else
			local p = tonumber(player:sub(-1))
			if WF.ITGFCType[p] < 4 then FlashColor = SL.JudgmentColors.ITG[WF.ITGFCType[p]] end
		end

		if (FlashColor ~= nil) then
			self:accelerate(0.25):diffuse( FlashColor )
				:accelerate(0.5):faderight(1):fadeleft(1)
				:accelerate(0.15):diffusealpha(0)
		end
	end,
	UpdateBGFilterPositionMessageCommand=function(self, params)
		if params.Player == player then
			local p = SCREENMAN:GetTopScreen():GetChild("Player"..pn)
			if p then
				self:x(p:GetX())
			end
		end
	end
}

-- At some point I might smooth out the lines or make a border around the elements to make it look better. 
-- as of now, the below implementation looks pretty ugly
--af[#af+1] = Def.Quad{
--	InitCommand=function(self)
--		self:xy(GetNotefieldX(player)-GetNotefieldWidth()/2, _screen.cy+80 )
--			:diffuse(Color.Black)
--			:diffuserightedge(0,0,0,mods.ScreenDarken)
--			:horizalign(right)
--			:zoomto( 50, _screen.h )
--			:diffuseleftedge(0,0,0,0)
--			--:valign(0)
--	end,
--}
--
--af[#af+1] = Def.Quad{
--	InitCommand=function(self)
--		self:xy(GetNotefieldX(player)+GetNotefieldWidth()/2, _screen.cy+80 )
--			:diffuse(Color.Black)
--			:diffuseleftedge(0,0,0,mods.ScreenDarken)
--			:horizalign(left)
--			:zoomto( 50, _screen.h )
--			:diffuserightedge(0,0,0,0)
--			--:valign(0)
--	end,
--}
	
	
return af