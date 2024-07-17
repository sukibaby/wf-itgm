local t = Def.ActorFrame{}

-- NumWheelItems under [MusicWheel] in Metrics.ini needs to be 17.
-- Only 15 can be seen onscreen at once, but we use 1 extra on top and
-- 1 extra at bottom so that MusicWheelItems don't visually
-- appear/disappear too suddenly while quickly scrolling through the wheel.

-- For this file just use a hardcoded 15, for the sake of animating the
-- "downward cascade" effect that occurs when SelectMusic first appears.
local NumWheelItems = 15

-- Each MusicWheelItem has two Quads drawn in front of it, blocking it from view.
-- Each of these Quads is half the height of the MusicWheelItem, and their y-coordinates
-- are such that there is an "upper" and a "lower" Quad.

-- The upper Quad has cropbottom applied while the lower Quad has croptop applied
-- resulting in a visual effect where the MusicWheelItems appear to "grow" out of the center to full-height.

local baseSleepTime = 0.05
local animationDuration = 0.1
local initialAlpha = 0.25

for i=1,NumWheelItems-2 do
	local sleepTime = baseSleepTime * i
	local yPosUpper = 9 + (_screen.h/NumWheelItems)*i
	local yPosLower = 25 + (_screen.h/NumWheelItems)*i
	local quadWidth = _screen.w/2
	local quadHeight = (_screen.h/NumWheelItems)/2

	-- upper
	t[#t+1] = Def.Quad{
		InitCommand=function(self)
			self:x( _screen.cx+_screen.w/4 )
				:y( yPosUpper )
				:zoomto(quadWidth, quadHeight)
				:diffuse( Color.Black )
		end,
		OnCommand=function(self)
			self:sleep(sleepTime):linear(animationDuration):cropbottom(1):diffusealpha(initialAlpha):queuecommand("Hide")
		end,
		HideCommand=function(self) self:visible(false) end
	}
	-- lower
	t[#t+1] = Def.Quad{
		InitCommand=function(self)
			self:x( _screen.cx+_screen.w/4 )
				:y( yPosLower )
				:zoomto(quadWidth, quadHeight)
				:diffuse( Color.Black )
		end,
		OnCommand=function(self)
			self:sleep(sleepTime):linear(animationDuration):croptop(1):diffusealpha(initialAlpha):queuecommand("Hide")
		end,
		HideCommand=function(self) self:visible(false) end
	}
end

return t