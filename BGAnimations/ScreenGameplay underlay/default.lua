-- if the MenuTimer is enabled, we should reset SSM's MenuTimer now that we've reached Gameplay
if PREFSMAN:GetPreference("MenuTimer") then
	SL.Global.MenuTimer.ScreenSelectMusic = ThemePrefs.Get("ScreenSelectMusicMenuTimer")
end

local Players = GAMESTATE:GetHumanPlayers()
local t = Def.ActorFrame{ Name="GameplayUnderlay" }

-- life bar controller (shared since it handles both players)
-- this needs to load before steps statistics to properly load lifebar graphics
t[#t+1] = LoadActor("./Shared/LifeBarController.lua")

for player in ivalues(Players) do
	
	t[#t+1] = LoadActor("./PerPlayer/StepStatistics/default.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/Danger.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/BackgroundFilter.lua", player)
end

-- UI elements shared by both players
t[#t+1] = LoadActor("./Shared/VersusStepStatistics.lua")
t[#t+1] = LoadActor("./Shared/Header.lua")
t[#t+1] = LoadActor("./Shared/SongInfoBar.lua") -- song title and progress bar

-- per-player UI elements
for player in ivalues(Players) do
	t[#t+1] = LoadActor("./PerPlayer/UpperNPSGraph.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/Score.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/DifficultyMeter.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/LifeMeter/default.lua", player)
	
	-- I'll put the custom measure counters in a separate file to avoid clutter and potentially messing something up which creates lag lol
	t[#t+1] = LoadActor("./PerPlayer/MeasureCounter.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/MeasureCounterCustom.lua", player)
	
	t[#t+1] = LoadActor("./PerPlayer/TargetScore/default.lua", player)
		
	t[#t+1] = LoadActor("./PerPlayer/SubtractiveScoring.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/SubtractiveScoringPace.lua", player)
	
	t[#t+1] = LoadActor("./PerPlayer/EarlyLate.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/OffsetDisplay.lua", player)
	
	-- custom lifebar stuff
	t[#t+1] = LoadActor("./PerPlayer/AutoRegenController.lua", player)
	-- itg tracking
	t[#t+1] = LoadActor("./PerPlayer/ITGTrack.lua", player)
	
	-- Simple fail notification to tell you when you ITG and WF fail
	t[#t+1] = LoadActor("./PerPlayer/FailNotification.lua", player)
	
	-- Fail tracker for custom evaluation sound on pass/fail
	t[#t+1] = LoadActor("./PerPlayer/FailTracker.lua", player)
	t[#t+1] = LoadActor("./PerPlayer/DisplayMods.lua", player)

	-- all the NoteField stuff is here
	t[#t+1] = LoadActor("./PerPlayer/NoteField/default.lua", player)
end

-- add to the ActorFrame last; overlapped by StepStatistics otherwise
t[#t+1] = LoadActor("./Shared/BPMDisplay.lua")

return t
