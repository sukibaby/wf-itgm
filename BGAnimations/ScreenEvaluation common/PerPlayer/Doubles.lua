local af = Def.ActorFrame {
	InitCommand=function(self)
		SM("hello")
	end,
}


--local player = ...
--
--local DrawNinePanelPad = LoadActor( THEME:GetPathB("ScreenSelectStyle", "underlay/pad.lua") )
--
--local af = DrawNinePanelPad()..{
--	InitCommand=function(self)
--		--self:x(_screen.w - (PREFSMAN:GetPreference("MenuTimer") and WideScale(90,105) or WideScale(35, 41)))
--		--self:y( WideScale(22, 23.5) ):zoom(0.24)
--		self:x(0)
--		self:y(0)
--		SM(player)
--		self:playcommand("Set", {Player=PLAYER_1})
--
--	end
--},
---- P2 pad
--DrawNinePanelPad()..{
--	InitCommand=function(self)
--		--self:x(_screen.w - (PREFSMAN:GetPreference("MenuTimer") and WideScale(70,81) or WideScale(15, 17)))
--		--self:y( WideScale(22, 23.5) ):zoom(0.24)
--		self:x(30)
--		self:y(30)
--		self:playcommand("Set", {Player=PLAYER_2})
--	end
--}


return af