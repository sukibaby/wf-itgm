local args = ...
local player = args.player
local side = player
if args.sec then side = (player == PLAYER_1) and PLAYER_2 or PLAYER_1 end
local pn = tonumber(player:sub(-1))

local mods = SL[ToEnumShortString(player)].ActiveModifiers

local percent = WF.ITGScore[pn]
local expercent = WF.GetEXScore(player)

local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local PercentDP = stats:GetPercentDancePoints()
local percent = FormatPercentScore(PercentDP)
-- Format the Percentage string, removing the % symbol
percent = string.format("%.2f",percent:gsub("%%", ""))

-- If EX scoring is enabled, always show instead of the marquee
local displayExScore = mods.EXScoring

local t = Def.ActorFrame{
	Name="PercentageContainer"..ToEnumShortString(player),
	OnCommand=function(self)
		self:y( _screen.cy-26 )
	end,
	-- dark background quad behind player percent score
	Def.Quad{
		InitCommand=function(self)
			self:diffuse(color("#101519")):zoomto(158.5, 60)
			self:horizalign(side==PLAYER_1 and left or right)
			self:x(150 * (side == PLAYER_1 and -1 or 1))
		end
	},
	
	-- Only WF percent
	Def.ActorFrame {
		LoadFont("_wendy white")..{
			Name="Percent",
			Text=percent,
			InitCommand=function(self)
				self:horizalign(right):zoom(0.585)
				self:x( (side == PLAYER_1 and 1.5 or 141))
			end
		},
		InitCommand=function(self)
			if not displayExScore then
				self:sleep(2):queuecommand("Loop")
			else
				self:visible(false)
			end
		end,
		LoopCommand=function(self)
			self:diffusealpha(0):sleep(3):diffusealpha(1):sleep(3):queuecommand("Loop")
		end
	},
	
	-- Both WF and EX percent
	Def.ActorFrame {
		LoadFont("_wendy white")..{
			Name="EXPercent",
			Text=expercent,
			InitCommand=function(self)
				--self:horizalign(right):zoom(0.585)
				self:x( (side == PLAYER_1 and -110 or 29.5))
				self:horizalign(center):zoom(0.2925)
				self:y(10)
				self:diffuse(SL.JudgmentColors.ITG[1])
				
			end
		},
		LoadFont("_wendy white")..{
			Name="Percent",
			Text=percent,
			InitCommand=function(self)
				--self:horizalign(right):zoom(0.585)
				self:x( (side == PLAYER_1 and -30 or 112.5))
				self:horizalign(center):zoom(0.2925)			
				self:y(10)
				--self:diffuse(SL.JudgmentColors.ITG[1])
			end
		},
		-- labels
		LoadFont("_wendy white")..{
			Name="EXPercentLabel",
			Text="EX",
			InitCommand=function(self)
				--self:horizalign(right):zoom(0.585)
				self:x( (side == PLAYER_1 and -110 or 29.5))
				self:horizalign(center):zoom(0.2925)
				self:y(-15)
				self:diffuse(SL.JudgmentColors.ITG[1])
			end
		},
		LoadFont("_wendy white")..{
			Name="PercentLabel",
			Text="WF",
			InitCommand=function(self)
				--self:horizalign(right):zoom(0.585)
				self:x( (side == PLAYER_1 and -30 or 112.5))
				self:horizalign(center):zoom(0.2925)			
				self:y(-15)
				--self:diffuse(SL.JudgmentColors.ITG[1])
			end
		},
		InitCommand=function(self)
			if not displayExScore then
				self:diffusealpha(0)
				self:sleep(2):queuecommand("Loop")
			end
		end,
		LoopCommand=function(self)
			self:diffusealpha(1):sleep(3):diffusealpha(0):sleep(3):queuecommand("Loop")
		end
	}
	
}

return t

