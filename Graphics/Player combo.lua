local player = Var "Player"
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers
local p = tonumber(player:sub(-1))
local useitg = mods.SimulateITGEnv

local combo_font = "Wendy"

if mods.HideCombo or combo_font == nil then
	return Def.Actor{ InitCommand=function(self) self:visible(false) end }
end

-- standard colors
local colors_standard = {}
colors_standard.FullComboW1 = {color("#FF0080"), color("#FF0080")} -- pink combo
colors_standard.FullComboW2 = {color("#FFFF00"), color("#FFFF00")} -- gold combo
colors_standard.FullComboW3 = {color("#00c800"), color("#00c800")} -- green combo
colors_standard.FullComboW4 = {color("#0080FF"), color("#0080FF")} -- blue combo

-- combo colors used in ITG
local colors_itg = {}
colors_itg.FullComboW1 = {color("#C8FFFF"), color("#6BF0FF")} -- blue combo
colors_itg.FullComboW2 = {color("#FDFFC9"), color("#FDDB85")} -- gold combo
colors_itg.FullComboW3 = {color("#C9FFC9"), color("#94FEC1")} -- green combo
colors_itg.FullComboW4 = {color("#FFFFFF"), color("#FFFFFF")} -- white combo

local colors = (not useitg) and colors_standard or colors_itg

local ShowComboAt = (mods.ComboRotation ~= "None") and 1 or THEME:GetMetric("Combo", "ShowComboAt")

local af = Def.ActorFrame{
	InitCommand=function(self)
		self:draworder(101)
	end,
	ComboCommand=function(self, params)
		local CurrentCombo = params.Misses or ((not useitg) and params.Combo or WF.ITGCombo[p])
		if useitg and params.Misses and (WF.ITGCombo[p] > 0) then CurrentCombo = WF.ITGCombo[p] end

		-- if the combo has reached (or surpassed) the threshold to be shown, display the AF, otherwise hide it
		self:visible( CurrentCombo ~= nil and CurrentCombo >= ShowComboAt )
	end,
}


-- Combo fonts should be monospaced so that each digit's alignment remains
-- consistent (i.e., not visually distracting) as the combo continually grows
local combo_bmt = LoadFont("_Combo Fonts/Wendy/Wendy")..{
	Name="Number",
	OnCommand=function(self)
		self:shadowlength(1):vertalign(middle):zoom(0.75)
		ComboAmount = 0
	end,
	SongStartMessageCommand=function(self)
	    local MusicRate = GAMESTATE:GetSongOptionsObject("ModsLevel_Song"):MusicRate()
		local BPM = round(GAMESTATE:GetPlayerState(player):GetSongPosition():GetCurBPS()*60*MusicRate)
		self:rotationz(60/BPM):clockeffect("bgm")		
	end,
	ComboCommand=function(self, params)
		local combo = params.Misses or ((not useitg) and params.Combo or WF.ITGCombo[p])
		if useitg and params.Misses and (WF.ITGCombo[p] > 0) then combo = WF.ITGCombo[p] end
		self:settext( combo or "" )
		self:diffuseshift():effectperiod(0.8):playcommand("Color", params)
	end,
	ColorCommand=function(self, params)
		-- Though this if/else chain may seem strange (why not reduce it to a single table for quick lookup?)
		-- the FullCombo params passed in from the engine are also strange, so this accommodates.
		--
		-- the params table will always contain a "Combo" value if the player is comboing notes successfully
		-- or a "Misses" value if the player is not hitting any notes and earning consecutive misses.
		--
		-- Once we are 20% through the song (this value is specifed in Metrics.ini in the [Player] section
		-- using PercentUntilColorCombo), the engine will start to include FullCombo parameters.
		--
		-- If the player has only earned W1 judgments so far, the params table will look like:
		-- { Combo=1001, FullComboW1=true, FullComboW2=true, FullComboW3=true, FullComboW4=true }
		--
		-- if the player has earned some combination of W1 and W2 judgments, the params table will look like:
		-- { Combo=1005, FullComboW2=true, FullComboW3=true, FullComboW4=true }
		--
		-- And so on. While the information is technically true (a FullComboW2 does imply a FullComboW3), the
		-- explicit presence of all those parameters makes checking truthiness here in the theme a little
		-- awkward.  We need to explicitly check for W1 first, then W2, then W3, and so on...

		-- if using ITG, need to use WF.ITGFCType[p] instead

		if ((not useitg) and params.FullComboW1) or (useitg and WF.ITGFCType[p] == 1) then
			self:effectcolor1(colors.FullComboW1[1]):effectcolor2(colors.FullComboW1[2])

		elseif ((not useitg) and params.FullComboW2) or (useitg and WF.ITGFCType[p] == 2) then
			self:effectcolor1(colors.FullComboW2[1]):effectcolor2(colors.FullComboW2[2])

		elseif ((not useitg) and params.FullComboW3) or (useitg and WF.ITGFCType[p] == 3) then
			self:effectcolor1(colors.FullComboW3[1]):effectcolor2(colors.FullComboW3[2])

		elseif ((not useitg) and params.FullComboW4) or (useitg and WF.ITGFCType[p] == 4 and WF.ITGCombo[p] > 0) then
			self:effectcolor1(colors.FullComboW4[1]):effectcolor2(colors.FullComboW4[2])

		elseif ((not useitg) and params.Combo) or (useitg and WF.ITGFCType[p] == 4 and WF.ITGCombo[p] > 0) then
			self:stopeffect():diffuse( Color.White ) -- not a full combo; no effect, always just #ffffff

		elseif params.Misses then
			self:stopeffect():diffuse( Color.Red ) -- Miss Combo; no effect, always just #ff0000
		end
		
		-- Fun modifier menu. Lots of stuff inspired by Zankoku
		-- We both kinda just expanded on stupid ideas and this is the outcome
		
		local combo = (params.Misses and 0) or ((not useitg) and params.Combo or WF.ITGCombo[p])
		if useitg and params.Misses and (WF.ITGCombo[p] > 0) then combo = WF.ITGCombo[p] end
		-- Nice
		if mods.ComboEffectsNice then
			if (combo > 0 and combo < 69) then
				self:settext("less than 69")
			elseif (combo == 69) then
				self:settext("nice")
			elseif (combo > 69) then
				self:settext("more than 69")
			end
		end

		-- Combo Rotation Combo
		if (mods.ComboRotation == "Combo") then
			if (combo > 0) then
				self:rotationz(self:GetRotationZ()+2)
			else
				self:rotationz(self:GetRotationZ()-2)
			end
		end

		-- Combo Rotation Random
		if (mods.ComboRotation == "Random") then
				self:rotationz(math.random(1,360))
		end

		-- Combo Stretch Grow
		if mods.ComboStretchGrow then
			local newzoom = self:GetZoom()
			if (combo > 0) then
				newzoom = ((self:GetWidth()*self:GetZoom()) < GetNotefieldWidth()) and newzoom*1.002 or newzoom*1.001
			else
				newzoom = 0.75 
			end
			self:zoom(newzoom)
		end
		
		-- Combo Stretch Horizontal
		if mods.ComboStretchHorizontal then
			local newzoomx = self:GetZoomX()
			if (combo > 0) then
				newzoomx = ((self:GetWidth()*self:GetZoomX()) < GetNotefieldWidth()) and newzoomx*1.002 or newzoomx*1.001
			else 
				newzoomx = 0.75 
			end
			self:zoomx(newzoomx)
		end

		-- Combo Stretch Vertical
		if mods.ComboStretchVertical then
			if (combo > 0) then
				self:zoomy(self:GetZoomY()*1.001)
			else
				self:zoomy(0.75)
			end
		end
		
		-- Combo Stretch Random
		if mods.ComboStretchRandom then
			if (combo > 0) then
				if math.random() > 0.5 then
					self:zoomx(self:GetZoomX()*1.002)
				else
					self:zoomy(self:GetZoomY()*1.002)
				end
			else
				if math.random() > 0.5 then
					self:zoomx(0.75)
				else
					self:zoomy(0.75)
				end
			end
		end
		
		-- Rainbow combo
		if (mods.ComboRainbow ~= "None") then
			if mods.ComboRainbow == "Always" then self:rainbowscroll(true)
			else
				if (mods.ComboRainbow == "100" and combo >= 100)
				or (mods.ComboRainbow == "250" and combo >= 250)
				or (mods.ComboRainbow == "500" and combo >= 500)
				or (mods.ComboRainbow == "1000" and combo >= 1000)
				then
					self:rainbowscroll(true)
				end
			end
			if combo == 0 then self:rainbowscroll(false) end			
		end
		
-- Wild combo counter, an amalgamation of amazing ideas
if mods.ComboEffectsWild then
    local nfw = GetNotefieldWidth(pn) / 2
    self:rotationz(math.random(1, 360))
        :zoom(math.random() * combo / math.min(100, combo))
        :xy(math.random(-nfw, nfw), math.random(-nfw, nfw))

    local rand = math.random()
    if params.Misses then
        self:rainbowscroll(false):stopeffect():diffuse(Color.Red)
    else
        local colorIndex = math.ceil(rand * 5)
        local color = colorIndex < 5 and colors["FullComboW" .. (colorIndex - 1)][2] or Color.White
        self:rainbowscroll(colorIndex == 1):stopeffect():diffuse(color)
    end
end,
JudgmentMessageCommand = function(self, params)
    if params.Player ~= player then return end
    if (not useitg) and params.TapNoteScore and (params.TapNoteScore == "TapNoteScore_HitMine") then
        self:settext(""):zoom(0.75)
        if mods.ComboRainbow ~= "None" then self:rainbowscroll(false) end
    end
end,
-- Responsive combo. InputHandler in \BGAnimations\ScreenGameplay overlay\default.lua
ButtonPressMessageCommand = function(self, params)
    if params.Player == player then
        local moveAmount = mods.ComboEffectsResponsiveInverse and -1.5 or 1.5
        if params.Button == "Left" or params.Button == "Right" then
            self:addx(params.Button == "Left" and moveAmount or -moveAmount)
        elseif params.Button == "Up" or params.Button == "Down" then
            self:addy(params.Button == "Up" and moveAmount or -moveAmount)
        end
    end
end

af[#af+1] = combo_bmt


return af
