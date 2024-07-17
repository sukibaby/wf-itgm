-- Basically TaroNuke's catJAM mod

local player = ...
local pn = ToEnumShortString(player)

local mods = SL[pn].ActiveModifiers
if (mods.GIF == "None") then return end

local c = PREFSMAN:GetPreference("Center1Player")
local ar = GetScreenAspectRatio()
local ws = IsUsingWideScreen()
local x = (c and -67 or -89.8)*ar
if ws and ar < 1.7 then x = x +5.5 end

local y = -48
local zoom 	= (ws and not c) and 0.4 or 0.3		
		
t = Def.ActorFrame {
	OnCommand=function(self)
		self:xy(x,y)	
		self:zoom(zoom)
	end,
	LoadActor("./GIFs/".. mods.GIF .. ".lua", player)	
}

return t