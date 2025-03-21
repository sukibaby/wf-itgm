local sort_wheel = ...

-- this handles user input while in the SortMenu
local function input(event)
	if not (event and event.PlayerNumber and event.button) then
		return false
	end
	SOUND:StopMusic()

	local screen   = SCREENMAN:GetTopScreen()
	local overlay  = screen:GetChild("Overlay")
	local sortmenu = overlay:GetChild("SortMenu")

	if event.type ~= "InputEventType_Release" then

		if event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
			sort_wheel:scroll_by_amount(1)
			sortmenu:GetChild("change_sound"):play()

		elseif event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
			sort_wheel:scroll_by_amount(-1)
			sortmenu:GetChild("change_sound"):play()

		elseif event.GameButton == "Start" then
			sortmenu:GetChild("start_sound"):play()
			local focus = sort_wheel:get_actor_item_at_focus_pos()

			if focus.kind == "SortBy" then
				MESSAGEMAN:Broadcast('Sort',{order=focus.sort_by})
				overlay:queuecommand("DirectInputToEngine")

			elseif focus.kind == "ChangeEnvironment" then
				MESSAGEMAN:Broadcast("ChangeEnvironment")
			-- the player wants to change styles, for example from single to double
			elseif focus.kind == "ChangeStyle" then
				-- If the MenuTimer is in effect, make sure to grab its current
				-- value before reloading the screen.
				if PREFSMAN:GetPreference("MenuTimer") then
					overlay:playcommand("ShowPressStartForOptions")
				end

				-- Get the style we want to change to
				local new_style = focus.change:lower()

				-- accommodate techno game
				if GAMESTATE:GetCurrentGame():GetName()=="techno" then new_style = new_style.."8" end

				-- set it in the engine
				GAMESTATE:SetCurrentStyle(new_style)

				-- finally, reload the screen
				screen:SetNextScreenName("ScreenReloadSSM")
				screen:StartTransitioningScreen("SM_GoToNextScreen")

			elseif focus.new_overlay then
				if focus.new_overlay == "TestInput" then
					sortmenu:queuecommand("DirectInputToTestInput")
				elseif focus.new_overlay == "Leaderboard" then
					-- The leaderboard entry is removed altogether if the service isn't available.
					sortmenu:queuecommand("DirectInputToLeaderboard")
				elseif focus.new_overlay == "SongSearch" then
					-- Direct the input back to the engine, so that the ScreenTextEntry overlay
					-- works correctly.
					overlay:queuecommand("DirectInputToEngineForSongSearch")
				elseif focus.new_overlay == "LoadNewSongs" then
					-- Make sure we cancel the request if it's active before trying to switch screens.
					-- This prevents the "Stale ActorFrame" error.
					--overlay:GetChild("PaneDisplayMaster"):GetChild("GetScoresRequester"):playcommand("Cancel")
					overlay:playcommand("DirectInputToEngine")
					SCREENMAN:SetNewScreen("ScreenReloadSongsSSM")
				elseif focus.new_overlay == "AddFavorite" then
					addOrRemoveFavorite(event.PlayerNumber)
					-- Nudge the wheel a bit so that that the icon is correctly updated.
					overlay:queuecommand("DirectInputToEngine")
					local screen = SCREENMAN:GetTopScreen()
					screen:GetMusicWheel():Move(1)
					screen:GetMusicWheel():Move(-1)
					screen:GetMusicWheel():Move(0)
				elseif focus.new_overlay == "Preferred" then
					-- Only allow sorting by favorites if there are favorites available
					if (#SL[ToEnumShortString(event.PlayerNumber)].Favorites > 0) then
						-- The 2nd argument, isAbsolute, is ITGmania 0.6.0 specific. It
						-- allows absolute paths to be used for the favorites file which is
						-- how it works to load from the profile directory.
						SONGMAN:SetPreferredSongs(getFavoritesPath(event.PlayerNumber), --[[isAbsolute=]]true);
						if SONGMAN:GetPreferredSortSongs() then
							overlay:queuecommand("DirectInputToEngine")
							SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort("SortOrder_Preferred")
						else 
							SM(ToEnumShortString(event.PlayerNumber).." has no favorites!")
						end
					else
						SM("No Favorites Available")
					end
				end
			end

		elseif event.GameButton == "Back" or event.GameButton == "Select" then
			overlay:queuecommand("DirectInputToEngine")
		end
	end

	return false
end

return input
