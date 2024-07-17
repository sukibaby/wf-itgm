local darkness = 0.85
--local darkness2 = 0.85

-- As of 0.7.6, now using a slider for background filter under mods.ScreenDarken
--local FilterAlpha = {
--	Off = 0,
--	Dark = 0.5,
--	Darker = 0.75,
--	Darkest = 0.95
--}


-- Starting quad
local quad = Def.ActorFrame {
	Name="Header",
}

--determine 1 or 2 player mode
local style = GAMESTATE:GetCurrentStyle()
local styleType = style:GetStyleType()

if (styleType == "StyleType_OnePlayerOneSide" or styleType == "StyleType_OnePlayerTwoSides") then 
	
	-- Get background filter setting
	local Players = GAMESTATE:GetHumanPlayers()	
	local pn = ToEnumShortString(Players[1])	
	local mods = SL[pn].ActiveModifiers	
	darkness = mods.ScreenDarken  --FilterAlpha[mods.BackgroundFilter]
	
	quad[#quad+1] = Def.Quad{
		InitCommand=function(self)
			self:diffuse(0,0,0,darkness):valign(0):xy( _screen.cx, 0 )
			self:zoomtowidth(_screen.w):zoomtoheight(80)
		end
		}	
end

if (styleType == "StyleType_TwoPlayersTwoSides") then 
	local d = {}
	for player in ivalues(GAMESTATE:GetHumanPlayers()) do
		local pn = ToEnumShortString(player)
		local mods = SL[pn].ActiveModifiers	
		d[pn] = mods.ScreenDarken --FilterAlpha[mods.BackgroundFilter]
		
		-- draw quad for individual player's side
		quad[#quad+1] = Def.Quad {
			InitCommand=function(self)
				self:diffuse(0,0,0,d[pn]):valign(0)
				self:zoomto((pn == "P1" and GetNotefieldX(player) or _screen.w-GetNotefieldX(player)) + GetNotefieldWidth()/2,80)
				self:x(pn == "P1" and 0 or _screen.w):horizalign(pn == "P1" and left or right)
			end
		}
	end
	
	-- draw quad inbetween both players to blend the darkness filters together
	quad[#quad+1] = Def.Quad {
		InitCommand=function(self)
			if (d["P1"] == d["P2"]) then
				--self:diffuse(0,0,0,d["P1"])
				self:diffuse(0,0,0,1)
			else
				self:diffuseleftedge(0,0,0,d["P1"])
				self:diffuserightedge(0,0,0,d["P2"])	
			end
			self:valign(0)			
			
			-- Position and size
			-- This was kind of annoying to figure out lol
			self:zoomto(((GetNotefieldX("PlayerNumber_P2")-GetNotefieldWidth()/2)-(GetNotefieldX("PlayerNumber_P1")+GetNotefieldWidth()/2)),80)
			self:x(GetNotefieldX("PlayerNumber_P1")+GetNotefieldWidth()/2):horizalign(left)
		end
	}	
	
end





return quad