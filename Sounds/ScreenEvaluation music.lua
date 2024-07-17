local sounddir = THEME:GetCurrentThemeDirectory() .. "Sounds/"

audio_file = "ScreenEvaluation failed.ogg"
audio_file_loop = "ScreenEvaluation failed (loop).ogg"

audio_file_both = "ScreenEvaluation both.ogg"
audio_file_both_loop = "ScreenEvaluation both (loop).ogg"

local passed = false -- We want to know if at least one player passed

local players = GAMESTATE:GetHumanPlayers()
for player in ivalues(players) do
	local pn = ToEnumShortString(player) 
	
	--Global Variable set in BGAnimations\ScreenGameplay underlay\PerPlayer\FailTracker.lua
	if not GAMESTATE:Env()["Fail" .. pn] then passed = true end 

end

if passed then
    audio_file = "ScreenEvaluation passed.ogg"
	audio_file_loop = "ScreenEvaluation passed (loop).ogg"
end

local sound = audio_file_loop
local checkexists = sounddir .. audio_file_loop

if not FILEMAN:DoesFileExist(checkexists) then 
	checkexists = sounddir .. audio_file 
	sound = audio_file	
end

if not FILEMAN:DoesFileExist(checkexists) then 
	checkexists = sounddir .. audio_file_both_loop
	sound = audio_file_both_loop
end

if not FILEMAN:DoesFileExist(checkexists) then 
	checkexists = sounddir .. audio_file_both
	sound = audio_file_both
end

if not FILEMAN:DoesFileExist(checkexists) then 
	sound = "_silent" 
end

return THEME:GetPathS("", sound)
