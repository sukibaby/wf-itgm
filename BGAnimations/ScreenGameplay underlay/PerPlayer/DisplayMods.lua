local player = ...
local pn = ToEnumShortString(player)
local pnum = tonumber(player:sub(-1))
local mods = SL[pn].ActiveModifiers
local options = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")

local round = function(number) -- to format X mod, this is probably the most inefficient way to do this
	local str = string.format("%.2f",number)
	if str:sub(-3) == ".00" 	then return string.format("%.f",number) end
	if str:sub(-1) == "0" 		then return string.format("%.1f",number) end	
	return str	
end

local useitg = mods.SimulateITGEnv
-- I don't know why there isn't just a Perspective varaible
local Perspective 
if options:Overhead() 	then Perspective = "Overhead" 	end
if options:Hallway() 	then Perspective = "Hallway" 	end
if options:Distant() 	then Perspective = "Distant" 	end
if options:Incoming() 	then Perspective = "Incoming" 	end
if options:Space() 		then Perspective = "Space" 		end

local SpeedMod = mods.SpeedModType .. mods.SpeedMod .. " " .. Perspective
if mods.SpeedModType == "X" then SpeedMod = round(mods.SpeedMod) .. "x " .. Perspective end

local significantmods = GetSignificantMods(player)
local modnames = {"Left","Right","Mirror","Shuffle","SuperShuffle"}

local Mini = "10%"
local Environment = useitg and "ITG" or "Waterfall"

local faults
if WF.SelectedErrorWindowSetting == 1 then faults = "Boys on (WF windows)"  end
if WF.SelectedErrorWindowSetting == 2 then faults = "Boys off"				end
if WF.SelectedErrorWindowSetting == 3 then faults = "Boys on (ITG Windows)"	end

local FAPlus = 0

local NoMines = options:NoMines()
local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
local num_mines = StepsOrTrail:GetRadarValues(player):GetValue("RadarCategory_Mines")
	
local FAPlus = "FA+ Off"
if mods.FAPlus == 0.01 then FAPlus = "10ms FA+" end
if mods.FAPlus == 0.015 and useitg then FAPlus = "15ms FA+" end

local values = {}

table.insert(values,Environment)
table.insert(values,SpeedMod)
table.insert(values,mods.Mini .. " Mini")
for mod in ivalues(significantmods) do
    local findmod = FindInTable(mod, modnames)
    if findmod then
		if mod == "SuperShuffle" then mod = "Blender" end
		table.insert(values,mod)
    end
end
table.insert(values,FAPlus)
table.insert(values,faults)
if NoMines and num_mines > 0 then table.insert(values,"No Mines") end


local af = Def.ActorFrame{
    InitCommand = function(self)
        self:xy(GetNotefieldX(player), SCREEN_HEIGHT/4*1.3)
    end,
	OnCommand=function(self)
		self:sleep(5):decelerate(0.5):diffusealpha(0)
	end
}

for i,text in ipairs(values) do
	af[#af+1] = Def.Quad {
		InitCommand=function(self)
			self:diffuse(Color.Black):diffusealpha(0.8)
			self:zoomto(125,15)
			self:y(15*(i-1))
		end
	}
	af[#af+1] = LoadFont("Common Normal")..{
		Text=text,
		InitCommand=function(self)
			self:y(15*(i-1))
			self:zoom(0.8)
			self:maxwidth(125)
		end,
	}
end

return af