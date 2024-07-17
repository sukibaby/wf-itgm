-- Adding back "No Mines" option into Waterfall requires changing of quite a few things
-- so I'm making a global variable with the amount of mines in the chart
-- otherwise I'd need to do the same piece of code in like 3-4 different places
-- Thanks teejusb for the help!

local player = ...
local pn = ToEnumShortString(player)

local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
local num_mines = StepsOrTrail:GetRadarValues(player):GetValue("RadarCategory_Mines")
	
GAMESTATE:Env()["TotalMines" .. pn] = num_mines