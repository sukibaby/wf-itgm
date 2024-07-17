local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers


local clap = Def.Sound{
    File = THEME:GetPathS("", "GameplayAssist clap.ogg"),
	ButtonPressMessageCommand = function(self, params)
		if params.Player == player then
			if params.Button == "Left" then self:play()
			elseif params.Button == "Right" then self:play()
			elseif params.Button == "Up" then self:play()
			elseif params.Button == "Down" then self:play()
			end
		end
	end
}


return clap