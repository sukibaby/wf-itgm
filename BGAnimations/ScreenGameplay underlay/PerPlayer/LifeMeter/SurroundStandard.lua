-- God this looks so ugly, especially in doubles mode
-- I reduced the opacity to make it look a little better
-- I hope nobody ever uses WF surround lifebar
-- - Zarzob

local args = ...

local lbind = args.index
local player = args.player
local pn = tonumber(player:sub(-1))
local mods = SL["P"..pn].ActiveModifiers

local c = WF.LifeBarColors[lbind]



local af = Def.ActorFrame{
	Name="LifeMeter_"..ToEnumShortString(player),
	InitCommand=function(self)
		self:xy(0,0)
	end,
	WFLifeChangedMessageCommand=function(self,params)
		if (params.pn == pn and params.ind == lbind) then
			local life = (params.newlife / WF.LifeBarMetrics[lbind].MaxValue)
			self:playcommand("ChangeSize", {CropAmount=(1-life) })
		end
	end,
	WFLifeBarFailedMessageCommand = function(self, params)
		if params.pn ~= pn then return end
		if params.ind > WF.PreferredLifeBar[pn] then return end
		if params.ind == lbind and lbind ~= WF.LowestLifeBarToFail[pn] then
			self:finishtweening()
			self:queuecommand("Hide")
		elseif params.ind == lbind + 1 and lbind >= WF.LowestLifeBarToFail[pn] then
			self:finishtweening()
			self:queuecommand("Show")
		end
	end,
}

-- if double style, we want two quads flanking the left/right sides of the screen that move in unison
if GAMESTATE:GetCurrentStyle():GetName():gsub("8","") == "double" then
	af[#af+1] = Def.Quad{
		Name="Left_"..lbind,
		InitCommand=function(self)
			self:vertalign(top)
				:zoomto( _screen.w/2, _screen.h-80 )
				:horizalign(left):diffuse(c[1],c[2],c[3],1):faderight(0.8):xy(0, 80):diffusealpha(0.3)
		end,
		OnCommand=function(self)
			self:diffusealpha(WF.PreferredLifeBar[pn] == lbind and 0.3 or 0)
			--local startlife = 1-WF.ITGLife[pn]
			--self:croptop(startlife) 
		end,
		ShowCommand = function(self)
			self:linear(0.2)
			self:diffusealpha(0.3)
			--self:visible(true)
		end,
		HideCommand = function(self)
			self:linear(0.2)
			self:diffusealpha(0)
			--self:visible(false)
		end,
		
		ChangeSizeCommand=function(self, params)
			self:finishtweening():smooth(0.2):croptop(params.CropAmount)
		end,
		DeadCommand=function(self)
			self:finishtweening():smooth(0.2):croptop(1)
		end
	}

	af[#af+1] = Def.Quad{
		Name="Right_"..lbind,
		InitCommand=function(self)
		self:vertalign(top)
			:zoomto( _screen.w/2, _screen.h-80 )
			:horizalign(right):diffuse(c[1],c[2],c[3],1):fadeleft(0.8):xy(_screen.w, 80):diffusealpha(0.3)
		end,
		OnCommand=function(self)
			self:diffusealpha(WF.PreferredLifeBar[pn] == lbind and 0.3 or 0)
			--local startlife = 1-WF.ITGLife[pn]
			--self:croptop(startlife) 
		end,
		ShowCommand = function(self)
			self:linear(0.2)
			self:diffusealpha(0.3)
			--self:visible(true)
		end,
		HideCommand = function(self)
			self:linear(0.2)
			self:diffusealpha(0.3)
			--self:visible(false)
		end,
		
		ChangeSizeCommand=function(self, params)
			self:finishtweening():smooth(0.2):croptop(params.CropAmount)
		end,
		DeadCommand=function(self)
			self:finishtweening():smooth(0.2):croptop(1)
		end
	}

------if single or versus style, we want one uniquely-moving quad per player
else
	af[#af+1] = Def.Quad{
		Name="MeterFill_"..lbind;
		InitCommand=function(self)
			self:vertalign(top)
				:zoomto( _screen.w/2, _screen.h-80 )
			if player == PLAYER_1 then
				self:horizalign(left):diffuse(c[1],c[2],c[3],1):faderight(0.8):xy(0, 80):diffusealpha(0.3)
			else
				self:horizalign(right):diffuse(c[1],c[2],c[3],1):fadeleft(0.8):xy(_screen.w, 80):diffusealpha(0.3)
			end
		end,
		OnCommand=function(self)
			self:diffusealpha(WF.PreferredLifeBar[pn] == lbind and 0.3 or 0)
			--local startlife = 1-WF.ITGLife[pn]
			--self:croptop(startlife) 
		end,
		ShowCommand = function(self)
			self:linear(0.2)
			self:diffusealpha(0.3)
			--self:visible(true)
		end,
		HideCommand = function(self)
			self:linear(0.2)
			self:diffusealpha(0)
			--self:visible(false)
		end,
		
		ChangeSizeCommand=function(self, params)
			self:finishtweening():smooth(0.2):croptop(params.CropAmount)
		end,
		DeadCommand=function(self)
			self:finishtweening():smooth(0.2):croptop(1)
		end
	}
end

return af