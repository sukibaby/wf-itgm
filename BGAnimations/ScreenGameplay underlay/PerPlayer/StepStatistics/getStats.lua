local player = ...
local pn = ToEnumShortString(player)
local pnum = tonumber(player:sub(-1))

local af = Def.ActorFrame {
	OnCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local ss_pane = screen:GetChild("Underlay"):GetChild("StepStatistics"..pn)
		local info = { 
			_screen.cx,
			_screen.cy, 
			_screen.w,
			GetScreenAspectRatio(),
			ss_pane:GetX(),
			ss_pane:GetY(),
			ss_pane:GetWidth(),
			ss_pane:GetHeight(),
			GetNotefieldWidth(player)
			}
		SM(info)
	end,
}
return af