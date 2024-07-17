local player = Var "Player"
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers
local sprite
local text

------------------------------------------------------------
-- A profile might ask for a judgment graphic that doesn't exist
-- If so, use the first available Judgment graphic
-- If that fails too, fail gracefully and do nothing

local useitg = SL[pn].ActiveModifiers.SimulateITGEnv
local available_judgments = GetJudgmentGraphics(useitg and "ITG" or nil)

local file_to_load = (FindInTable(mods.JudgmentGraphic, available_judgments) ~= nil and mods.JudgmentGraphic or available_judgments[1]) or "None"

if file_to_load == "None" then
	return Def.Actor{ InitCommand=function(self) self:visible(false) end }
end

local usetext = (file_to_load == "Plain Text")

if useitg and (not usetext) then file_to_load = "itg/"..file_to_load end

local threshold = mods.FAPlus
if (not useitg) and threshold == 0.015 then threshold = 0 end

------------------------------------------------------------

local TNSFrames = {
	TapNoteScore_W1 = 0,
	TapNoteScore_W2 = 2,
	TapNoteScore_W3 = 3,
	TapNoteScore_W4 = 4,
	TapNoteScore_W5 = 5,
	TapNoteScore_Miss = 6
}

local af = Def.ActorFrame{
	Name="Player Judgment",
	InitCommand=function(self)
		local kids = self:GetChildren()
		sprite = kids.JudgmentWithOffsets
		if usetext then
			text = kids.PlainTextJudgment
		end
	end,
	JudgmentMessageCommand=function(self, param)
		if param.Player ~= player then return end
		if not param.TapNoteScore then return end
		if param.HoldNoteScore then return end

		-- if in "ITG" mode, display the frame based on the ITG judgment by calculating it from the offset
		local TNSToUse = param.TapNoteScore
		if useitg and (TNSToUse ~= "TapNoteScore_Miss" and TNSToUse ~= "TapNoteScore_AvoidMine"
		and TNSToUse ~= "TapNoteScore_HitMine") then
			local window = DetermineTimingWindow(param.TapNoteOffset, "ITG")
			TNSToUse = "TapNoteScore_W"..window
		end
		
		local judgement = usetext and text or sprite
		
		-- Fun mod stuff
		local TNO = param.TapNoteOffset and param.TapNoteOffset or 0
		if mods.JudgementsTilt and not mods.JudgementsCumulativeTilt then
				judgement:rotationz(TNO * 300)
			end
			
		if mods.JudgementsCumulativeTilt then
			judgement:rotationz(judgement:GetRotationZ()+TNO * 100)
		end

		if mods.JudgementsRandomTilt then
			judgement:rotationz(math.random(1,360))
		end
		
		-- sprite based commands
		if not usetext then
			-- "frame" is the number we'll use to display the proper portion of the judgment sprite sheet
			-- Sprite actors expect frames to be 0-indexed when using setstate() (not 1-indexed as is more common in Lua)
			-- an early W1 judgment would be frame 0, a late W2 judgment would be frame 3, and so on
			local frame = TNSFrames[ TNSToUse ]
			if not frame then return end

			-- judgment fonts now have only 7 frames, with frame 1 being "white w1"
			if TNSToUse == "TapNoteScore_W1" and threshold > 0 and math.abs(param.TapNoteOffset) > threshold then
				frame = 1
			end

			self:playcommand("Reset")

			sprite:visible(true):setstate(frame)
			
			local wild = mods.JudgementsWild and math.random(0.625,1.5) or 1
			local ez = mods.JudgementsWild and math.random(0.3,1.4) or 0
			
			-- this should match the custom JudgmentTween() from SL for 3.95
			sprite:zoom(0.8*wild):decelerate(0.1):zoom(0.75*wild):sleep(0.6):accelerate(0.2):zoom(ez)
			
		else
			local mode = (not useitg) and "Waterfall" or "ITG"
			local ind = ToEnumShortString(TNSToUse)
			local word = WF.PlainTextJudgmentNames[mode][ind]
			if not word then return end
			self:playcommand("Reset")
			local cind = (ind ~= "Miss") and tonumber(ind:sub(-1)) or 6
			text:settext(word)
			if threshold > 0 and ((param.TapNoteOffset) and ind == "W1" and math.abs(param.TapNoteOffset) > threshold) then
				text:diffuse(Color.White)
			else
				text:diffuse(SL.JudgmentColors[mode][cind])
			end
			text:visible(true)
			local bz = mods.JudgementsWild and math.random(0.625,1.5) or WF.PlainTextJudgmentBaseZoom
			local ez = mods.JudgementsWild and math.random(0.3,1.4) or 0
			text:zoom(0.8*bz):decelerate(0.1):zoom(0.75*bz):sleep(0.6):accelerate(0.2):zoom(ez)
			
		end
		-- Wild judgements, I didn't intend for it to behave like this but it's hilarious so I'm keeping it
		if mods.JudgementsWild then
			local nfw = GetNotefieldWidth(pn)/2
			judgement:stopeffect():rotationz(math.random(1, 360)):zoom(math.random(0.5,3)):x(math.random(nfw * -1,nfw)):y(math.random(nfw * -1,nfw))
		end
	end,
	-- Responsive judgement. Input Handler in BGAnimations\ScreenGameplay overlay\default.lua
	ButtonPressMessageCommand = function(self, params)
		local judgement = usetext and text or sprite
		if params.Player == player then
			if mods.JudgementsResponsive then
				if params.Button == "Left" then judgement:stopeffect():addx(-1.5)
				elseif params.Button == "Right" then judgement:stopeffect():addx(1.5)
				elseif params.Button == "Up" then judgement:stopeffect():addy(-1.5)
				elseif params.Button == "Down" then judgement:stopeffect():addy(1.5)
				end
			end
			if mods.JudgementsResponsiveInverse then					
				if params.Button == "Left" then judgement:stopeffect():addx(1.5)
				elseif params.Button == "Right" then judgement:stopeffect():addx(-1.5)
				elseif params.Button == "Up" then judgement:stopeffect():addy(1.5)
				elseif params.Button == "Down" then judgement:stopeffect():addy(-1.5)
				end
			end
		end
	end,
	
	Def.Sprite{
		Name="JudgmentWithOffsets",
		InitCommand=function(self)
			-- animate(false) is needed so that this Sprite does not automatically
			-- animate its way through all available frames; we want to control which
			-- frame displays based on what judgment the player earns
			self:animate(false):visible(false)

			-- if we are on ScreenEdit, judgment graphic is always "Love"
			-- because ScreenEdit is a mess and not worth bothering with.
			if string.match(tostring(SCREENMAN:GetTopScreen()), "ScreenEdit") then
				self:Load( THEME:GetPathG("", "_judgments/Optimus Dark") )

			elseif file_to_load ~= "Plain Text" then
				self:Load( THEME:GetPathG("", "_judgments/" .. file_to_load) )
			end
		end,
		ResetCommand=function(self) self:finishtweening():stopeffect():visible(false) end
	}
}

if usetext then
	af[#af+1] = LoadFont(WF.PlainTextJudgmentFont)..{
		Name = "PlainTextJudgment",
		InitCommand = function(self)
			self:visible(false)
		end,
		ResetCommand = function(self)
			self:finishtweening():stopeffect():visible(false)
		end
	}
end

return af