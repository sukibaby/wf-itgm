local player = ...
local pn = ToEnumShortString(player)
local pnum = tonumber(player:sub(-1))
local mods = SL[pn].ActiveModifiers

if not mods.FailNotification then return end

local af = Def.ActorFrame{
    InitCommand = function(self)
        self:xy(GetNotefieldX(player), _screen.cy)
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

af[#af+1] = LoadFont("Common Normal")..{
	Name="Failed Text",
	Text="Failed",
	InitCommand=function(self)
		self:visible(false)
		self:y(60)
	end,
	ITGFailedMessageCommand=function(self,params)
		if params.pn == pnum then
			self:visible(true)
			self:settext("ITG Failed")			
			self:diffusealpha(1):sleep(2.5):decelerate(1):diffusealpha(0)
		end
	end,
	WFFailedMessageCommand=function(self,params)
		if params.pn == pnum then
			self:visible(true)
			self:settext("WF Failed")			
			self:diffusealpha(1):sleep(2.5):decelerate(1):diffusealpha(0)
		end
	end,
}

return af
