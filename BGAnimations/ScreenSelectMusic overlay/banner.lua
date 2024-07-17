local banner_directory = THEME:GetPathG("","_FallbackBanners/Arrows")

local SongOrCourse, banner

local t = Def.ActorFrame{
	OnCommand=function(self)
		local zoomLevel = IsUsingWideScreen() and 0.7655 or 0.75
		local xOffset = IsUsingWideScreen() and -170 or -166
		self:zoom(zoomLevel):xy(_screen.cx + xOffset, 96)
	end,

	Def.ActorFrame{
		CurrentSongChangedMessageCommand=function(self) self:playcommand("Set") end,
		CurrentCourseChangedMessageCommand=function(self) self:playcommand("Set") end,
		SetCommand=function(self)
			SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
			self:visible(not (SongOrCourse and SongOrCourse:HasBanner()))
		end,

		LoadActor(banner_directory.."/banner"..SL.DefaultColor.." (doubleres).png" )..{
			Name="FallbackBanner",
			OnCommand=function(self) self:rotationy(180):setsize(418,164):diffuseshift():effectoffset(3):effectperiod(6):effectcolor1(1,1,1,0):effectcolor2(1,1,1,1) end
		},

		LoadActor(banner_directory.."/banner"..SL.DefaultColor.." (doubleres).png" )..{
			Name="FallbackBanner",
			OnCommand=function(self) self:diffuseshift():effectperiod(6):effectcolor1(1,1,1,0):effectcolor2(1,1,1,1):setsize(418,164) end
		},
	},

	Def.ActorProxy{
		Name="BannerProxy",
		BeginCommand=function(self)
			banner = SCREENMAN:GetTopScreen():GetChild('Banner')
			self:SetTarget(banner)
		end
	},

	-- the MusicRate Quad and text
	Def.ActorFrame{
		InitCommand=function(self)
			self:visible(SL.Global.ActiveModifiers.MusicRate ~= 1):y(75)
		end,

		Def.Quad{
			InitCommand=function(self) self:diffuse(color("#1E282FCC")):zoomto(418,14) end
		},

		LoadFont("Common Normal")..{
			InitCommand=function(self) self:shadowlength(1):zoom(0.85) end,
			OnCommand=function(self)
				self:settext(("%g"):format(SL.Global.ActiveModifiers.MusicRate) .. "x " .. THEME:GetString("OptionTitles", "MusicRate"))
			end
		}
	}
}

return t
