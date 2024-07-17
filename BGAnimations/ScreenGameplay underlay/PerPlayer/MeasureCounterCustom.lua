local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers

-- don't allow MeasureCounter to appear in Casual gamemode via profile settings
if SL.Global.GameMode == "Casual" or not mods.MeasureCounter or mods.MeasureCounter == "None" or mods.CustomMeasureCounter == "None" then
	return
end

-- -----------------------------------------------------------------------

local PlayerState = GAMESTATE:GetPlayerState(player)
local streams, prevMeasure, streamIndex
-- Collection of the BitmapText actors used for the measure counters.
local bmt = {}

-- How many streams to "look ahead"
local lookAhead = mods.HideLookahead and 0 or 1 -- Probably don't want more than 1 lookahead for this lol
-- If you want to see more than 2 counts in advance, change the 2 to a larger value.
-- Making the value very large will likely impact fps. -quietly


-- We'll want to reset each of these values for each new song in the case of CourseMode
local InitializeMeasureCounter = function()
	-- SL[pn].Streams is initially set (and updated in CourseMode)
	-- in ./ScreenGameplay in/MeasureCounterAndModsLevel.lua
	streams = SL[pn].Streams
	streamIndex = 1
	prevMeasure = -1

	for actor in ivalues(bmt) do
		actor:visible(true)
	end
end

-- Returns whether or not we've reached the end of this stream segment.
local IsEndOfStream = function(currMeasure, Measures, streamIndex)
	if Measures[streamIndex] == nil then return false end

	-- a "segment" can be either stream or rest
	local segmentStart = Measures[streamIndex].streamStart
	local segmentEnd   = Measures[streamIndex].streamEnd

	local currStreamLength = segmentEnd - segmentStart
	local currCount = math.floor(currMeasure - segmentStart) + 1

	return currCount > currStreamLength
end

local Counter
local EnglishSucks

-- English language is stupid
if mods.CustomMeasureCounter == "Encoder" then Counter = 32 EnglishSucks = "Encoders" end
if mods.CustomMeasureCounter == "Crush" then Counter = 120  EnglishSucks = "Crushes" end
if mods.CustomMeasureCounter == "Oceanlab" then Counter = 512  EnglishSucks = "Oceanlabs" end

local Plural = function(number)
	if number == 1 then return mods.CustomMeasureCounter else return EnglishSucks
	end
end

local round = function(number)
	local DecimalPoints = 1
	local str = string.format("%."..DecimalPoints.."f",number)
	if str == "1.000" then return "1" else return str end
end

local GetTextForMeasure = function(currMeasure, Measures, streamIndex, isLookAhead)
	if currMeasure < 0 then
		if not isLookAhead then
			-- Measures[1] is guaranteed to exist as we check for non-empty tables at the start of Update() below.
			if not Measures[1].isBreak then
				-- currMeasure can be negative. If the first thing is a stream, then denote that "negative space" as a rest.
				return "(" .. round(currMeasure * -1 + 1) .. ") " .. Plural(currMeasure * -1 + 1)
			else
				-- If the first thing is a break, then add the negative space to the existing break count
				local segmentStart = Measures[1].streamStart
				local segmentEnd   = Measures[1].streamEnd
				local currStreamLength = segmentEnd - segmentStart
				--return "(" .. math.floor(currMeasure * -1) + 1 + currStreamLength .. ")"
				return "(" .. round((currMeasure * -1 + 1 + currStreamLength)/Counter) .. ") " .. Plural(currMeasure * -1 + 1 + currStreamLength/Counter)
			end
		else
			if not Measures[1].isBreak then
				-- Push all the stream segments back by one since we're adding an additional ephemeral break.
				streamIndex = streamIndex - 1
			end
		end
	end
	if Measures[streamIndex] == nil then return "" end

	-- A "segment" can be either stream or rest
	local segmentStart = Measures[streamIndex].streamStart
	local segmentEnd   = Measures[streamIndex].streamEnd

	local currStreamLength = segmentEnd - segmentStart
	local currCount = math.floor(currMeasure - segmentStart) + 1

	local text = ""
	if Measures[streamIndex].isBreak then
		if mods.HideLookahead ~= 0 then
			if not isLookAhead then
				local remainingRest = currStreamLength - currCount + 1

				-- Ensure that the rest count is in range of the total length.
				text = "(" .. round(remainingRest/Counter) .. ") " .. Plural(remainingRest/Counter)
			else
				text = "(" .. round(currStreamLength/Counter) .. ") " .. Plural(currStreamLength/Counter)
			end
		end
	else
		if not isLookAhead and currCount ~= 0 then
			text = tostring(round(currCount/Counter) .. "/" .. round(currStreamLength/Counter)) .. " " .. Plural(currStreamLength/Counter)
		else
			text = tostring(round(currStreamLength/Counter)) .. " " .. Plural(currStreamLength/Counter)
		end
	end
	return text
end

local Update = function(self, delta)
	-- Check to make sure we even have any streams populated to display.
	if not streams.Measures or #streams.Measures == 0 then return end

	-- Things to look into:
	-- 1. Does PlayerState:GetSongPosition() take split timing into consideration?  Do we need to?
	-- 2. This assumes each measure is comprised of exactly 4 beats.  Is it safe to assume this?
	local currMeasure = (math.floor(PlayerState:GetSongPosition():GetSongBeatVisible()))/4

	-- If a new measure has occurred
	if currMeasure > prevMeasure then
		prevMeasure = currMeasure

		-- If we've reached the end of the stream, we want to get values for the next stream.
		if IsEndOfStream(currMeasure, streams.Measures, streamIndex) then
			streamIndex = streamIndex + 1
		end

		for i=1,lookAhead+1 do
			-- Only the first one is the main counter, the other ones are lookaheads.
			local isLookAhead = i ~= 1
			-- We're looping forwards, but the BMTs are indexed in the opposite direction.
			-- Adjust indices accordingly.
			local adjustedIndex = lookAhead+2-i
			local text = GetTextForMeasure(currMeasure, streams.Measures, streamIndex + i - 1, isLookAhead)
			bmt[adjustedIndex]:settext(text)
			-- We can hit nil when we've run out of streams/breaks for the song. Just hide these BMTs.
			if streams.Measures[streamIndex + i - 1] == nil then
				bmt[adjustedIndex]:visible(false)

			-- rest count
			elseif streams.Measures[streamIndex + i - 1].isBreak then
				-- Make rest lookaheads be lighter than active rests.
				if not isLookAhead then
					bmt[adjustedIndex]:diffuse(0.5, 0.5, 0.5 ,1)
				else
					bmt[adjustedIndex]:diffuse(0.4, 0.4, 0.4 ,1)
				end

			-- stream count
			else
				-- Make stream lookaheads be lighter than active streams.
				if not isLookAhead then
					if string.find(text, "/") then
						bmt[adjustedIndex]:diffuse(1, 1, 1, 1)
					else
						-- If this is a mini-break, make it lighter.
						bmt[adjustedIndex]:diffuse(0.5, 0.5, 0.5 ,1)
					end
				else
					bmt[adjustedIndex]:diffuse(0.45, 0.45, 0.45 ,1)
				end
			end
		end
	end
end

-- I'm not crazy about special-casing "Wendy" to use
-- _wendy small for the Measure/Rest counter, but
-- I'm hesitant to visually alter a feature that
-- so many players have become so reliant on...
local font = "_wendy small"

-- -----------------------------------------------------------------------

local af = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(GetNotefieldX(player),  _screen.cy)
		self:queuecommand("SetUpdate")
	end,
	SetUpdateCommand=function(self) self:SetUpdateFunction( Update ) end,

	CurrentSongChangedMessageCommand=function(self)
		InitializeMeasureCounter()
	end,
}

-- We iterate backwards since we want the lookaheads to be drawn first in the case the
-- main measure counter expands into them.
for i=lookAhead+1,1,-1 do
	af[#af+1] = LoadFont(font)..{
		InitCommand=function(self)
			-- Add to the collection of BMTs so our AF's update function can easily access them.
			bmt[#bmt+1] = self

			local width = GetNotefieldWidth()-80
			local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
			local columnWidth = width/NumColumns

			-- Have descending zoom sizes for each new BMT we add.
			self:zoom(0.3 - 0.05 * (i-1)):shadowlength(1):horizalign(center)
			self:x(columnWidth * (3 * (i-1)))
			if mods.MeasureCounterLeft then
				self:addx(-columnWidth)
			end
		end
	}
end

return af