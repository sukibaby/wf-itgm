------------------------------------------------------------
-- set up the SortMenu's choices first, prior to Actor initialization

-- sick_wheel_mt is a metatable with global scope defined in ./Scripts/Consensual-sick_wheel.lua
local sort_wheel = setmetatable({}, sick_wheel_mt)

local players = GAMESTATE:GetHumanPlayers()
local styletype = ToEnumShortString(GAMESTATE:GetCurrentStyle():GetStyleType()) -- Check for doubles mode
local pn = ToEnumShortString(players[1])

		
-- the logic that handles navigating the SortMenu
-- (scrolling through choices, choosing one, canceling)
-- is large enough that I moved it to its own file
local sortmenu_input = LoadActor("SortMenu_InputHandler.lua", sort_wheel)
local testinput_input = LoadActor("TestInput_InputHandler.lua")
local leaderboard_input = LoadActor("Leaderboard_InputHandler.lua")

local info_input = function(event)
	-- simple input callback to just handle the select button being held in 2 player mode
	if #GAMESTATE:GetHumanPlayers() ~= 2 then return false end

	if event.type == "InputEventType_FirstPress" then
		if event.GameButton == "Select" then
			MESSAGEMAN:Broadcast("SetTechText", {PlayerNumber = event.PlayerNumber})
		elseif event.GameButton == "Start" then
			MESSAGEMAN:Broadcast("SetInfoText", {PlayerNumber = "PlayerNumber_P1"})
			MESSAGEMAN:Broadcast("SetInfoText", {PlayerNumber = "PlayerNumber_P2"})
		end
	elseif event.type == "InputEventType_Release" then
		if event.GameButton == "Select" then
			MESSAGEMAN:Broadcast("SetInfoText", {PlayerNumber = event.PlayerNumber})
		end
	end

	return false
end

local FilterTable = function(arr, func)
	local new_index = 1
	local size_orig = #arr
	for v in ivalues(arr) do
		if func(v) then
			arr[new_index] = v
			new_index = new_index + 1
		end
	end
	for i = new_index, size_orig do arr[i] = nil end
end

local SongSearchSettings = {
	Question="'pack/song' format will search for songs in specific packs\n'[###]' format will search for BPMs/Difficulties",
	InitialAnswer="",
	MaxInputLength=30,
	OnOK=function(input)
		if #input == 0 then return end

		-- Lowercase the input text for comparison
		local searchText = input:lower()

		-- First extract out the "numbers".
		-- Anything <= 35 is considered a difficulty, otherwise it's a bpm.
		local difficulty = nil
		local bpmTier = nil

		for match in searchText:gmatch("%[(%d+)]") do
			local value = tonumber(match)
			if value <= 35 then
				difficulty = value
			else
				-- Determine the "tier".
				bpmTier = GetBpmTier(value)
			end
		end

		-- Remove the parsed atoms, and then strip leading/trailing whitespace.
		searchText = searchText:gsub("%[%d+]", ""):gsub("^%s*(.-)%s*$", "%1")

		-- The we separate out the pack and song into their own search terms.
		local packName = nil
		local songName = nil

		local forwardSlashIdx = searchText:find('/')
		if not forwardSlashIdx then
			songName = searchText
		else
			packName = searchText:sub(1, forwardSlashIdx - 1)
			songName = searchText:sub(forwardSlashIdx + 1)
		end

		-- Normalize empty strings to nil.
		if packName and #packName == 0 then packName = nil end
		if songName and #songName == 0 then songName = nil end

		-- If we have no search criteria, then return early.
		if not (packName or songName or difficulty or bpmTier) then return end

		-- Start with the complete song list.
		local candidates = SONGMAN:GetAllSongs()
		local stepsType = GAMESTATE:GetCurrentStyle():GetStepsType()

		-- Only add valid candidates if there are steps in the current mode.
		FilterTable(candidates, function(song) return song:HasStepsType(stepsType) end)

		if songName then
			FilterTable(candidates, function(song)
				return (song:GetDisplayFullTitle():lower():find(songName) ~= nil or
						song:GetTranslitFullTitle():lower():find(songName) ~= nil)
			end)
		end

		if packName then
			FilterTable(candidates, function(song) return song:GetGroupName():lower():find(packName) end)
		end

		if difficulty then
			FilterTable(candidates, function(song)
				local allSteps = song:GetStepsByStepsType(stepsType)
				for steps in ivalues(allSteps) do
					-- Don't consider edits.
					if steps:GetDifficulty() ~= "Difficulty_Edit" then
						if steps:GetMeter() == difficulty then
							return true
						end
					end
				end
				return false
			end)
		end

		if bpmTier then
			FilterTable(candidates, function(song)
				-- NOTE(teejusb): Not handling split bpms now, sorry.
				local bpms = song:GetDisplayBpms()
				if bpms[2]-bpms[1] == 0 then
					-- If only one BPM, then check to see if it's in the same tier.
					return bpmTier == GetBpmTier(bpms[1])
				else
					-- Otherwise check and see if the bpm is in the span of the tier.
					local lowTier = GetBpmTier(bpms[1])
					local highTier = GetBpmTier(bpms[2])
					return lowTier <= bpmTier and bpmTier <= highTier
				end
			end)
		end

		-- Even if we don't have any results, we want to show that to the player.
		MESSAGEMAN:Broadcast("DisplaySearchResults", {searchText=input, candidates=candidates})
	end,
}

-- WheelItemMT is a generic definition of an choice within the SortMenu
-- "mt" is my personal means of denoting that it (the file, the variable, whatever)
-- has something to do with a Lua metatable.
--
-- metatables in Lua are a useful construct when designing reusable components,
-- but many online tutorials and guides are incredibly obtuse and unhelpful
-- for non-computer-science people (like me). https://lua.org/pil/13.html is just frustratingly scant.
--
-- http://phrogz.net/lua/LearningLua_ValuesAndMetatables.html is less bad than most.
-- I get immediately lost in the criss-crossing diagrams, and I'll continue to
-- argue that naming things foo, bar, and baz abstract programming tutorials right
-- out of practical reality, but I found its prose to be practical, applicable, and concise,
-- so I guess I'll recommend that tutorial until I find a more helpful one.
local wheel_item_mt = LoadActor("WheelItemMT.lua")

local sortmenu = { w=210, h=160 }

-- if neither player is on itg mode, don't bother adding gs leaderboard option to menu.
-- we can assess that right away since (currently) you can't change gameplay mode while in the menu
-- (i do plan to change that though)
local showgsoption = false
for player in ivalues(GAMESTATE:GetHumanPlayers()) do
--	if SL[ToEnumShortString(player)].ActiveModifiers.SimulateITGEnv then
		showgsoption = true
		break
--	end
end

local hasSong = GAMESTATE:GetCurrentSong() and true or false

------------------------------------------------------------

local t = Def.ActorFrame {
	Name="SortMenu",

	-- Always ensure player input is directed back to the engine when initializing SelectMusic.
	InitCommand=function(self) self:visible(false):queuecommand("DirectInputToEngine") end,
	-- Always ensure player input is directed back to the engine when leaving SelectMusic.
	OffCommand=function(self) self:playcommand("DirectInputToEngine") end,

	-- Figure out which choices to put in the SortWheel based on various current conditions.
	OnCommand=function(self) self:playcommand("AssessAvailableChoices") end,
	-- We'll want to (re)assess available choices in the SortMenu if a player late-joins
	PlayerJoinedMessageCommand=function(self, params) self:queuecommand("AssessAvailableChoices") end,

	ChangeEnvironmentMessageCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()

		--screen:RemoveInputCallback(sortmenu_input)
		--screen:RemoveInputCallback(testinput_input)
		--screen:RemoveInputCallback(leaderboard_input)
		if SL[pn].ActiveModifiers.SimulateITGEnv == true then
			SL[pn].ActiveModifiers.SimulateITGEnv = false
		else
			SL[pn].ActiveModifiers.SimulateITGEnv = true
		end

		screen:SetNextScreenName("ScreenReloadSSM")
		screen:StartTransitioningScreen("SM_GoToNextScreen")
	end,
	
	-- this is for checking for the leaderboard
	CurrentSongChangedMessageCommand=function(self)
		if showgsoption and IsServiceAllowed(SL.GrooveStats.Leaderboard) then
			local curSong = GAMESTATE:GetCurrentSong()
			if (curSong and not hasSong) or (not curSong and hasSong) then
				self:queuecommand("AssessAvailableChoices")
			end
			hasSong = curSong and true or false
		end
	end,


	ShowSortMenuCommand=function(self) self:visible(true) end,
	HideSortMenuCommand=function(self) self:visible(false) end,

	DirectInputToSortMenuCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()

		screen:RemoveInputCallback(testinput_input)
		screen:RemoveInputCallback(leaderboard_input)
		screen:RemoveInputCallback(info_input)
		screen:AddInputCallback(sortmenu_input)

		for player in ivalues(GAMESTATE:GetHumanPlayers()) do
			SCREENMAN:set_input_redirected(player, true)
		end
		self:playcommand("ShowSortMenu")
		overlay:playcommand("HideTestInput")
		overlay:playcommand("HideLeaderboard")
	end,
	DirectInputToTestInputCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()

		screen:RemoveInputCallback(sortmenu_input)
		screen:RemoveInputCallback(info_input)
		screen:AddInputCallback(testinput_input)

		for player in ivalues(GAMESTATE:GetHumanPlayers()) do
			SCREENMAN:set_input_redirected(player, true)
		end
		self:playcommand("HideSortMenu")
		overlay:playcommand("ShowTestInput")
	end,
	DirectInputToLeaderboardCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()

		screen:RemoveInputCallback(sortmenu_input)
		screen:RemoveInputCallback(info_input)
		screen:AddInputCallback(leaderboard_input)

		for player in ivalues(PlayerNumber) do
			SCREENMAN:set_input_redirected(player, true)
		end
		self:playcommand("HideSortMenu")
		
		overlay:playcommand("ShowLeaderboard")
	end,
	-- this returns input back to the engine and its ScreenSelectMusic
	DirectInputToEngineCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()

		screen:RemoveInputCallback(sortmenu_input)
		screen:RemoveInputCallback(testinput_input)
		screen:AddInputCallback(info_input)

		for player in ivalues(GAMESTATE:GetHumanPlayers()) do
			SCREENMAN:set_input_redirected(player, false)
		end
		self:playcommand("HideSortMenu")
		overlay:playcommand("HideTestInput")
		overlay:playcommand("HideLeaderboard")
	end,
	DirectInputToEngineForSongSearchCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()

		screen:RemoveInputCallback(sortmenu_input)
		screen:RemoveInputCallback(testinput_input)
		screen:RemoveInputCallback(leaderboard_input)

		for player in ivalues(PlayerNumber) do
			SCREENMAN:set_input_redirected(player, false)
		end
		self:playcommand("HideSortMenu")
		overlay:playcommand("HideTestInput")
		overlay:playcommand("HideLeaderboard")

		-- Then add the ScreenTextEntry on top.
		SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
		SCREENMAN:GetTopScreen():Load(SongSearchSettings)
	end,

	AssessAvailableChoicesCommand=function(self)
		--self:visible(false)
		
		--SM("hello") 
		-- normally I would give variables like these file scope, and not declare
		-- within OnCommand(), but if the player uses the SortMenu to switch from
		-- single to double, we'll need reassess which choices to present.

		-- a style like "single", "double", "versus", "solo", or "routine"
		-- remove the possible presence of an "8" in case we're in Techno game
		-- and the style is "single8", "double8", etc.
		local style = GAMESTATE:GetCurrentStyle():GetName():gsub("8", "")

		local wheel_options = {
			{"SortBy", "Group"},
			{"SortBy", "Title"},
			{"SortBy", "Artist"},
			{"SortBy", "Genre"},
			{"SortBy", "BPM"},
			{"SortBy", "Length"},
            {"SortBy", "Meter"},
		}

		table.insert(wheel_options, {"SortBy", "Popularity"})
		table.insert(wheel_options, {"SortBy", "Recent"})

		-- Allow toggle between ITG and WF mode. No idea if this will work in 2 player mode.
		if (#players == 1) then 
			if (SL[pn].ActiveModifiers.SimulateITGEnv == true) then
				table.insert(wheel_options, {"ChangeEnvironment", "WF"})
			else
				table.insert(wheel_options, {"ChangeEnvironment", "ITG"})
			end
		end


		-- Allow players to switch from single to double and from double to single
		-- but only present these options if Joint Double or Joint Premium is enabled
		if not (PREFSMAN:GetPreference("Premium") == "Premium_Off" and GAMESTATE:GetCoinMode() == "CoinMode_Pay") then

			if style == "single" then
				if ThemePrefs.Get("AllowDanceSolo") then
					table.insert(wheel_options, {"ChangeStyle", "Solo"})
				end

				table.insert(wheel_options, {"ChangeStyle", "Double"})

			elseif style == "double" then
				table.insert(wheel_options, {"ChangeStyle", "Single"})

			elseif style == "solo" then
				table.insert(wheel_options, {"ChangeStyle", "Single"})

			-- Routine is not ready for use yet, but it might be soon.
			-- This can be uncommented at that time to allow switching from versus into routine.
			-- elseif style == "versus" then
			--	table.insert(wheel_options, {"ChangeStyle", "Routine"})
			end
		end

		-- allow players to switch to a TestInput overlay if the current game has visual assets to support it
		-- and if we're in EventMode (public arcades probably don't want random players attempting to diagnose the pads...)
		local game = GAMESTATE:GetCurrentGame():GetName()
		if (game=="dance" or game=="pump" or game=="techno") and GAMESTATE:IsEventMode() then
			table.insert(wheel_options, {"FeelingSalty", "TestInput"})
		end

		-- Reload songs, feature for ITGmania only
		table.insert(wheel_options, {"TakeABreather", "LoadNewSongs"})

		if not GAMESTATE:IsCourseMode() then
			if ThemePrefs.Get("KeyboardFeatures") then				
				-- Only display this option if keyboard features are enabled
				table.insert(wheel_options, {"WhereforeArtThou", "SongSearch"})
			end
		end

		-- The relevant Leaderboard.lua actor is only added if these same conditions are met.
		if showgsoption and IsServiceAllowed(SL.GrooveStats.Leaderboard) then
			-- Also only add this if we're actually hovering over a song.
			if GAMESTATE:GetCurrentSong() then
				table.insert(wheel_options, {"GrooveStats", "Leaderboard"})
			end
		end

        if GAMESTATE:GetCurrentSong() ~= nil then
            table.insert(wheel_options, {"ImLovinIt", "AddFavorite"})
        end

        for player in ivalues(GAMESTATE:GetHumanPlayers()) do
            local path = getFavoritesPath(player)
            if FILEMAN:DoesFileExist(path) then
                table.insert(wheel_options, {"MixTape", "Preferred"})
                break
            end
        end

		-- Override sick_wheel's default focus_pos, which is math.floor(num_items / 2)
		--
		-- keep in mind that num_items is the number of Actors in the wheel (here, 7)
		-- NOT the total number of things you can eventually scroll through (#wheel_options = 14)
		--
		-- so, math.floor(7/2) gives focus to the third item in the wheel, which looks weird
		-- in this particular usage.  Thus, set the focus to the wheel's current 4th Actor.
		sort_wheel.focus_pos = 4

		-- get the currently active SortOrder and truncate the "SortOrder_" from the beginning
		local current_sort_order = ToEnumShortString(GAMESTATE:GetSortOrder())
		local current_sort_order_index = 1

		-- find the sick_wheel index of the item we want to display first when the player activates this SortMenu
		for i=1, #wheel_options do
			if wheel_options[i][1] == "SortBy" and wheel_options[i][2] == current_sort_order then
				current_sort_order_index = i
				break
			end
		end

		-- the second argument passed to set_info_set is the index of the item in wheel_options
		-- that we want to have focus when the wheel is displayed
		sort_wheel:set_info_set(wheel_options, current_sort_order_index)
	end,

	-- slightly darken the entire screen
	Def.Quad {
		InitCommand=function(self) self:FullScreen():diffuse(Color.Black):diffusealpha(0.8) end
	},

	-- OptionsList Header Quad
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu.w+2,22):xy(_screen.cx, _screen.cy-92) end
	},
	-- "Options" text
	Def.BitmapText{
		Font="_wendy small",
		Text=ScreenString("Options"),
		InitCommand=function(self)
			self:xy(_screen.cx, _screen.cy-92):zoom(0.4)
				:diffuse( Color.Black )
		end
	},

	-- white border
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu.w+2,sortmenu.h+2) end
	},
	-- BG of the sortmenu box
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu.w,sortmenu.h):diffuse(Color.Black) end
	},
	-- top mask
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu.w,_screen.h/2):y(40):MaskSource() end
	},
	-- bottom mask
	Def.Quad {
		InitCommand=function(self) self:zoomto(sortmenu.w,_screen.h/2):xy(_screen.cx,_screen.cy+200):MaskSource() end
	},

	-- "Press SELECT To Cancel" text
	Def.BitmapText{
		Font="_wendy small",
		Text=ScreenString("Cancel"),
		InitCommand=function(self)
			if PREFSMAN:GetPreference("ThreeKeyNavigation") then
				self:visible(false)
			else
				self:xy(_screen.cx, _screen.cy+100):zoom(0.3):diffuse(0.7,0.7,0.7,1)
			end
		end
	},

	-- this returns an ActorFrame ( see: ./Scripts/Consensual-sick_wheel.lua )
	sort_wheel:create_actors( "Sort Menu", 7, wheel_item_mt, _screen.cx, _screen.cy )
}

t[#t+1] = LoadActor( THEME:GetPathS("ScreenSelectMaster", "change") )..{ Name="change_sound", SupportPan = false }
t[#t+1] = LoadActor( THEME:GetPathS("common", "start") )..{ Name="start_sound", SupportPan = false }

return t
