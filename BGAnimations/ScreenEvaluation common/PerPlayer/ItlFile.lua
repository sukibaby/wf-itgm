local player = ...
local pn = ToEnumShortString(player)

local year = Year()
local month = MonthOfYear()+1
local day = DayOfMonth()

local IsEventActive = function()
	-- The file is only written to while the event is active.
	-- These are just placeholder dates.
	local startTimestamp = 20220323
	local endTimestamp = 20220626

	local today = year * 10000 + month * 100 + day

	return startTimestamp <= today and today <= endTimestamp
end

local style = GAMESTATE:GetCurrentStyle()
local game = GAMESTATE:GetCurrentGame()

if (GAMESTATE:IsCourseMode() or
		not IsEventActive() or
		game:GetName() ~= "dance" or
		(style:GetName() ~= "single" and style:GetName() ~= "versus")) then
	return
end


-- Used to encode the lines of the file.
local Encode = function(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	return ((data:gsub('.', function(x) 
		local r , b = '', x:byte()
		for i = 8, 1, -1 do
			r = r..(b % 2^i - b % 2^(i-1) > 0 and '1' or '0')
		end
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c = 0
		for i = 1,6 do
			c = c + (x:sub(i,i) == '1' and 2^(6 - i) or 0)
		end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data % 3 + 1])
end


local DataForSong = function(pn, stats)
	-- TODO(teejusb): Have a helper function to get the appropriate judgment counts
	-- so we don't have to duplicate this logic.
		-- Used to send extra information to GrooveStats
	-- initially used to create the extra fields needed for ITL 2022
	--usedCmod (boolean)	
	--JudgmentCounts 
	-- 		fantasticPlus
	-- 		fantastic
	-- 		excellent
	-- 		great
	-- 		decent
	-- 		wayOff
	-- 		miss
	-- 		totalSteps
	-- 		minesHit
	-- 		totalMines
	-- 		holdsHeld
	-- 		totalHolds
	-- 		rollsHeld
	-- 		totalRolls
	
	local pn = ToEnumShortString(player)
	local pnum = tonumber(player:sub(-1))
	local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

	-- Cheat mod
	local options = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")	
	local usedCmod = tostring( options:CMod() and true or false )
	
	-- Create table for ITL
	local judgmentCounts = {}
	
	-- fantasticPlus and fantastic
	local blues = pss:GetTapNoteScores("TapNoteScore_W1")
	local whites = WF.ITGJudgmentCounts[pnum][1]-pss:GetTapNoteScores("TapNoteScore_W1")
	
	judgmentCounts[#judgmentCounts+1] = blues
	judgmentCounts[#judgmentCounts+1] = whites
	judgmentCounts[#judgmentCounts+1] = WF.ITGJudgmentCounts[pnum][2]
	judgmentCounts[#judgmentCounts+1] = WF.ITGJudgmentCounts[pnum][3]
	
	if WF.SelectedErrorWindowSetting == 3 then
		-- Decents are only enabled when fault window is set to "Extended"
		judgmentCounts[#judgmentCounts+1] = WF.ITGJudgmentCounts[pnum][4]
	else 
		judgmentCounts[#judgmentCounts+1] = ""
	end
	
	if WF.SelectedErrorWindowSetting ~= 2 then
		-- Way offs are enabled when fault window is either Enabled or Extended
		-- In other words, not disabled
		judgmentCounts[#judgmentCounts+1] = WF.ITGJudgmentCounts[pnum][5]
	else
		judgmentCounts[#judgmentCounts+1] = ""
	end
	
	judgmentCounts[#judgmentCounts+1] = WF.ITGJudgmentCounts[pnum][6]
	
	local possible = pss:GetRadarPossible()
	local actual = pss:GetRadarActual()	
	
	-- Dropped holds/rolls, mines
	local minesHit  = possible:GetValue("RadarCategory_Mines")-actual:GetValue("RadarCategory_Mines")
	local totalMines = possible:GetValue("RadarCategory_Mines")
	
	local holdsHeld = actual:GetValue("RadarCategory_Holds")
	local totalHolds = possible:GetValue("RadarCategory_Holds")
	
	local rollsHeld = actual:GetValue("RadarCategory_Rolls")
	local totalRolls = possible:GetValue("RadarCategory_Rolls")
	
	judgmentCounts[#judgmentCounts+1]	= holdsHeld
	judgmentCounts[#judgmentCounts+1]	= rollsHeld	
	judgmentCounts[#judgmentCounts+1]	= minesHit
	
	local steps = GAMESTATE:GetCurrentSteps(player)
	local hash = HashCacheEntry(steps)
	local date = ("%04d-%02d-%02d"):format(year, month, day)
	
	local line = ("%s,%s,%s,%s"):format(hash, table.concat(judgmentCounts, ","), usedCmod, date)
	return Encode(line).."\n"
end

local t = Def.ActorFrame {
	OnCommand=function(self)
		local pn = ToEnumShortString(player)

		local profile_slot = {
			[PLAYER_1] = "ProfileSlot_Player1",
			[PLAYER_2] = "ProfileSlot_Player2"
		}
		
		local dir = PROFILEMAN:GetProfileDir(profile_slot[player])
		local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
		
		-- Do the same validation as GrooveStats.
		-- This checks important things like timing windows, addition/removal of arrows, etc.
		local _, valid = ValidForGrooveStats(player)

		-- ITL additionally requires the music rate to be 1.00x.
		local so = GAMESTATE:GetSongOptionsObject("ModsLevel_Song")
		local rate = so:MusicRate()

		-- We also require mines to be on.
		local po = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")
		local mines_enabled = not po:NoMines()

		-- We require an explicit profile to be loaded.
		if (dir and #dir ~= 0 and
				GAMESTATE:IsHumanPlayer(player) and
				valid and
				rate == 1.0 and
				mines_enabled and
				not WF.ITGFailed[tonumber(player:sub(-1))]) then
			local path = dir.. "itl2022.itl"
			local f = RageFileUtil:CreateRageFile()
			-- Load the current contents of the file if it exists.
			local existing = ""
			if FILEMAN:DoesFileExist(path) then
				if f:Open(path, 1) then
					existing = f:Read()
				end
			end
			-- Append the new score to the file.
			if f:Open(path, 2) then
				f:Write(existing..DataForSong(pn, stats))
			end
			f:Close()
			f:destroy()
		end
	end
}

return t