local player = ...
local pn = tonumber(player:sub(-1))
local mods = SL["P"..pn].ActiveModifiers

local s = (mods.LifeMeterType == "Standard") and true or false
local c = PREFSMAN:GetPreference("Center1Player") and #GAMESTATE:GetHumanPlayers() == 1
local ws = IsUsingWideScreen()

-- Standard lifebar position/size
local w = 136
local h = 18
local _x = _screen.cx + WideScale(238, 288) * (pn*2-3)
local ystart = 20
local rot = 0
local voffset = 0
local yoffset = 0
local startlifew = w/2
local startlifeh = h

if not s then -- Vertical Lifebar position/size
	w = 250
	h = 16
	startlifew = w/2
	startlifeh = h
	_x = GetNotefieldX(player) + (GetNotefieldWidth(player)/2 + 16) * (pn*2-3)
	ystart = 275
	voffset = w/2
	yoffset = 125
	rot = -90
end

if GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred"):UsingReverse() and s then
	ystart = SCREEN_HEIGHT - 14
end

local swoosh, velocity

local Update = function(self)
	velocity = -GAMESTATE:GetSongBPS()/2
	if GAMESTATE:GetSongFreeze() then velocity = 0 end
	if swoosh then swoosh:texcoordvelocity(velocity,0) end
end

local meter = Def.ActorFrame{

	InitCommand=function(self) self:y(ystart):SetUpdateFunction(Update):visible(false) end,
	OnCommand=function(self) self:visible(true) end,

	-- frame
	Def.Quad{ InitCommand=function(self) self:x(_x):zoomto(w+4, h+4):rotationz(rot) end },
	Def.Quad{ InitCommand=function(self) self:x(_x):zoomto(w, h):diffuse(0,0,0,1):rotationz(rot) end },

	-- the Quad that changes width/color depending on current Life
	Def.Quad{
		Name="MeterFill",
		InitCommand=function(self) self:zoomto(w/2,h):y(yoffset):diffuse(PlayerColor(PLAYER_1)):horizalign(left):rotationz(rot) end,
		OnCommand=function(self) self:x( _x - w/2 + voffset) end,

		-- when the engine broadcasts that the player's LifeMeter value has changed
        -- change the width of this MeterFill Quad to accommodate
        -- also handle "hot" check here
        ITGLifeChangedMessageCommand=function(self,params)
            if params.pn == pn then
                if params.newlife == 1 then
					self:diffuse(1,1,1,1)
				else
                    -- ~~man's~~ lifebar's not hot
                    -- [TODO] for now, intentionally just using P1's "player color" because i don't like
                    -- the two lifebars being different colors. should eventually just have an ITGLifeBarColor
                    -- defined somewhere
					self:diffuse( PlayerColor(PLAYER_1) )
				end
				local life = params.newlife * w
				self:finishtweening()
				self:decelerate(0.1):zoomx( life )
			end
		end,
	},

	-- a simple scrolling gradient texture applied on top of MeterFill
	LoadActor("swoosh.png")..{
		Name="MeterSwoosh",
		InitCommand=function(self)
			swoosh = self

			self:zoomto(w*0.5,h)
				 :diffusealpha(0.2)
				 :horizalign( left )
				 :y(yoffset)
		end,
		OnCommand=function(self)
			self:x(_x - w/2+ voffset):rotationz(rot)
			self:customtexturerect(0,0,1,1)
			--texcoordvelocity is handled by the Update function below
        end,
        
        -- life-changing
		-- adjective
		--  /ˈlaɪfˌtʃeɪn.dʒɪŋ/
		-- having an effect that is strong enough to change someone's life
		-- synonyms: compelling, life-altering, puissant, blazing
		ITGLifeChangedMessageCommand=function(self,params)
			if (params.pn == pn) then
				if (params.newlife == 1) then
					self:diffusealpha(1)
				else
					self:diffusealpha(0.2)
                end
                
                local life = params.newlife * w
				self:finishtweening()
				self:decelerate(0.1):zoomto( life, h )
			end
		end
	}
}

return meter

-- copyright 2008-2012 AJ Kelly/freem.
-- do not use this code in your own themes without my permission.