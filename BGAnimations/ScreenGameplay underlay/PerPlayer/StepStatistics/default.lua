local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers
-- if the conditions aren't right, don't bother
if mods.DataVisualizations ~= "Step Statistics"
or GAMESTATE:GetCurrentStyle():GetName() ~= "single"
or (PREFSMAN:GetPreference("Center1Player") and not IsUsingWideScreen())
then
	return
end

local bg_and_judgments = Def.ActorFrame{
	Name="bg_and_judgements",
	InitCommand=function(self)
		if (PREFSMAN:GetPreference("Center1Player") and IsUsingWideScreen()) then
			-- 16:9 aspect ratio (approximately 1.7778)
			if GetScreenAspectRatio() > 1.7 then
				self:zoom(0.925)

			-- if 16:10 aspect ratio
			else
				self:zoom(0.825)
			end
		end
	end,

	LoadActor("./BackgroundAndBanner.lua", player),
	LoadActor("./GIF.lua", player),
	LoadActor("./StepsInfo.lua", player),
	LoadActor("./Time.lua", player),
	LoadActor("./JudgmentLabels.lua", player),
	LoadActor("./JudgmentNumbers.lua", player),
	LoadActor("./GSOverlay.lua", player),
	
}

return Def.ActorFrame{
	Name="StepStatistics"..pn,
	InitCommand=function(self)
		local x = _screen.w/4 * (player==PLAYER_1 and 3 or 1)
		local y = 80
		
		if (PREFSMAN:GetPreference("Center1Player") and IsUsingWideScreen()) then
			-- 16:9 aspect ratio (approximately 1.7778)
			if GetScreenAspectRatio() > 1.7 then
				x = x + (71.5 * (player==PLAYER_1 and 1 or -1))
				y = y + 0.5
			-- if 16:10 aspect ratio
			else
				x = x + (64.5 * (player==PLAYER_1 and 1 or -1))
				y = y + 2
			end
		end

		self:xy(x, _screen.cy + y)
	end,

	bg_and_judgments,
	LoadActor("./DensityGraph.lua", player),
}
