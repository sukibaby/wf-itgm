local player = ...
local pn = tonumber(player:sub(-1))

local mode = (not SL[ToEnumShortString(player)].ActiveModifiers.SimulateITGEnv) and "Waterfall" or "ITG"

local faplus = SL[ToEnumShortString(player)].ActiveModifiers.FAPlus

if faplus == 0 then
	faplus = false
end

local windows = SL.Global.ActiveModifiers.TimingWindows
if mode == "ITG" and ((not windows[5]) or (math.abs(PREFSMAN:GetPreference("TimingWindowSecondsW5") - 
	(SL.Preferences.ITG.TimingWindowSecondsW3 + SL.Preferences.ITG.TimingWindowAdd)) < 0.00001)) then
	windows = {true,true,true,false,false}
end

local possible, rv
local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
local total_tapnotes = StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Notes" )

-- determine how many digits are needed to express the number of notes in base-10
local digits = (math.floor(math.log10(total_tapnotes)) + 1)
-- display a minimum 4 digits for aesthetic reasons
digits = math.max(4, digits)

-- generate a Lua string pattern that will be used to leftpad with 0s
local pattern = ("%%0%dd"):format(digits)


local TapNoteScores = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
local TapNoteJudgments = { W1=0, W2=0, W3=0, W4=0, W5=0, Miss=0 }
local w1plus = 0
local w1minus = 0
local RadarCategories = { 'Holds', 'Mines', 'Rolls' }
local RadarCategoryJudgments = { Holds=0, Mines=0, Rolls=0 }

local leadingZeroAttr
local row_height = 35

local dir = pn*2 - 3

local t = Def.ActorFrame{
	InitCommand=function(self)
		self:zoom(0.8)
		self:y(90)
	end
}

local maxrows = #TapNoteScores

-- do "regular" TapNotes first
for index, window in ipairs(TapNoteScores) do

	-- push down for FA+
	local h = (index-1)*row_height - 282
	if (faplus) and index > 1 then h = h + row_height end
	
	-- player performance value
	t[#t+1] = LoadFont("_ScreenEvaluation numbers")..{
		Text=(pattern):format(0),
		InitCommand=function(self)
			self:zoom(0.5):horizalign( pn == 1 and right or left )
			
			--Trace("I'M LOADED")

			if windows[index] or index==#TapNoteScores then
				self:diffuse( SL.JudgmentColors[mode][index] )
				leadingZeroAttr = { Length=(digits-1), Diffuse=Brightness(self:GetDiffuse(), 0.35) }
				self:AddAttribute(0, leadingZeroAttr )
			else
				self:diffuse(Brightness({1,1,1,1},0.25))
			end
		end,
		BeginCommand=function(self)
			self:x( 8 * dir )
			self:y(h)

			-- horizontally squishing the numbers isn't pretty, but I'm not sure what else to do
			-- when people want to play "24 hours of 100 bpm stream" on a 4:3 monitor
			if not IsUsingWideScreen() and digits > 5 then
				self:x(4*dir):maxwidth(185)
			end
		end,
		JudgmentMessageCommand=function(self, params)
			if params.Player ~= player then return end
			if params.HoldNoteScore then return end
			
			--Trace("I'M LOADED. PLAYER "..pn.." JUST GOT "..params.TapNoteScore)

			local checkjudgment = params.TapNoteScore
			if mode == "ITG" and checkjudgment ~= "TapNoteScore_AvoidMine" and checkjudgment ~= "TapNoteScore_Miss"
			and checkjudgment ~= "TapNoteScore_HitMine" and params.TapNoteOffset then
				checkjudgment = "TapNoteScore_W"..(DetermineTimingWindow(params.TapNoteOffset, "ITG"))
			end

			if checkjudgment and ToEnumShortString(checkjudgment) == window then
				TapNoteJudgments[window] = TapNoteJudgments[window] + 1

				-- condition for fa+
				local numtouse = TapNoteJudgments[window]
				if (faplus) and window == "W1" then
					if math.abs(params.TapNoteOffset) <= faplus then w1plus = w1plus + 1
					else
						w1minus = w1minus + 1
						MESSAGEMAN:Broadcast("UpdateW1Minus", {Player = player, n = w1minus})
					end
					numtouse = w1plus
				end
				self:settext( (pattern):format(numtouse) )

				leadingZeroAttr = {
					Length=(digits - (math.floor(math.log10(numtouse))+1)),
					Diffuse=Brightness(SL.JudgmentColors[mode][index], 0.35)
				}
				self:AddAttribute(0, leadingZeroAttr )

				MESSAGEMAN:Broadcast("UpdateFAPlus", {Player = player})
			end
		end
	}

	-- add text for FA+
	if (faplus) and index == 1 then
		t[#t+1] = LoadFont("_ScreenEvaluation numbers")..{
			Text=(pattern):format(0),
			InitCommand=function(self)
				self:zoom(0.5):horizalign( pn == 1 and right or left )
	
				self:diffuse( Color.White )
				leadingZeroAttr = { Length=(digits-1), Diffuse=Brightness(self:GetDiffuse(), 0.35) }
				self:AddAttribute(0, leadingZeroAttr )
			end,
			BeginCommand=function(self)
				self:x( 8*dir )
				self:y(h + row_height)
	
				if not IsUsingWideScreen() and digits > 5 then
					self:x(4*dir):maxwidth(185)
				end
			end,
			UpdateW1MinusMessageCommand=function(self, params)
				if params.Player ~= player then return end
				
				local whites = params.n
	
				self:settext( (pattern):format(whites) )

				leadingZeroAttr = {
					Length=(digits - (math.floor(math.log10(whites))+1)),
					Diffuse=Brightness(Color.White, 0.35)
				}
				self:AddAttribute(0, leadingZeroAttr )
			end
		}
	end

end

-- then handle holds, mines, hands, rolls
for index, RCType in ipairs(RadarCategories) do

	-- player performance value
	t[#t+1] = LoadFont("_ScreenEvaluation numbers")..{
		Text="000",
		InitCommand=function(self) self:zoom(0.4):horizalign( pn == 1 and right or left ) end,
		BeginCommand=function(self)
			--self:y((index-1)*row_height - 178)
			self:y((index-1 + maxrows+1)*row_height - 282)
			self:x( 30*dir )

			leadingZeroAttr = { Length=2, Diffuse=color("#5A6166") }
			self:AddAttribute(0, leadingZeroAttr )
		end,
		JudgmentMessageCommand=function(self, params)
			if params.Player ~= player then return end
			if not params.TapNoteScore then return end

			if RCType=="Mines" and params.TapNoteScore == "TapNoteScore_HitMine" then
			
				RadarCategoryJudgments.Mines = RadarCategoryJudgments.Mines + 1
				self:settext( string.format("%03d", RadarCategoryJudgments.Mines) )

			elseif RCType=="Holds" and params.TapNote and params.TapNote:GetTapNoteSubType() == "TapNoteSubType_Hold" then
			
				if params.HoldNoteScore and params.HoldNoteScore == "HoldNoteScore_Held" then
					RadarCategoryJudgments.Holds = RadarCategoryJudgments.Holds + 1
					self:settext( string.format("%03d", RadarCategoryJudgments.Holds) )
				end

			elseif RCType=="Rolls" and params.TapNote and params.TapNote:GetTapNoteSubType() == "TapNoteSubType_Roll" then
				
				if params.HoldNoteScore and params.HoldNoteScore == "HoldNoteScore_Held" then
					RadarCategoryJudgments.Rolls = RadarCategoryJudgments.Rolls + 1
					self:settext( string.format("%03d", RadarCategoryJudgments.Rolls) )
				end
				
			end

			leadingZeroAttr = { Length=(3-tonumber(tostring(RadarCategoryJudgments[RCType]):len())), Diffuse=color("#5A6166") }
			self:AddAttribute(0, leadingZeroAttr )
		end
	}
	
	-- extra stuff text
	t[#t+1] = LoadFont("Common normal")..{
		Text="",
		InitCommand=function(self) self:zoom(1) end,
		BeginCommand=function(self)
			--self:y((index-1)*row_height - 178)
			self:y((index-1 + maxrows+1)*row_height - 282)
			self:x( 0 )
			
			self:settext(THEME:GetString("ScreenEvaluation", RCType))
		end
	}

end

return t