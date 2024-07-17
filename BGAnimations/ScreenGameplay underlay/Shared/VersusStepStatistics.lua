local Players = GAMESTATE:GetHumanPlayers()

local ShouldDisplayStatsForPlayer = function(player)
    local pn = ToEnumShortString(player)
    return SL[pn].ActiveModifiers.DataVisualizations == "Step Statistics"
end

local ShouldDisplayStats = function()
    if GAMESTATE:GetCurrentStyle():GetName() ~= "versus" or not IsUsingWideScreen() then
        return false
    end

    local shouldDisplay = false
    for player in ivalues(Players) do
        if ShouldDisplayStatsForPlayer(player) then
            shouldDisplay = true
        end
    end
    return shouldDisplay
end

if not ShouldDisplayStats() then
    return
end

local af = Def.ActorFrame{
    InitCommand=function(self)
		self:Center()
    end
}

for player in ivalues(Players) do
    if ShouldDisplayStatsForPlayer(player) and #Players > 1 then
	
		local pn = tonumber(player:sub(-1))
	
        af[#af+1] = Def.Quad{
            InitCommand=function(self)
                self:diffuse(0,0,0,1)
				self:horizalign( pn == 1 and right or left )
				self:zoomto(110,SCREEN_HEIGHT)
				self:x(-30*(pn*2-3))
            end,
			OnCommand=function(self)
				local p = SCREENMAN:GetTopScreen():GetChild("PlayerP"..pn)
				if p then
					--p:addx(20 * (pn*2-3))
					MESSAGEMAN:Broadcast("UpdateBGFilterPosition", {Player = player})
				end
				self:sleep(2)
				self:queuecommand("UpdateBGFilterPosition")
			end
        }
        
    end
end

for player in ivalues(Players) do
    if ShouldDisplayStatsForPlayer(player) and #Players > 1 then
	
        local numbers = LoadActor("../PerPlayer/StepStatistics/JudgmentNumbersVersus.lua", player)
        af[#af+1] = numbers
		
    end
end

return af