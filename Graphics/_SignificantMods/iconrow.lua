local player = ...
local pn = ToEnumShortString(player)
local mods = GetSignificantMods(player)
local modnames = {"C","Left","Right","Mirror","Shuffle","SuperShuffle","SoftShuffle"}

-- Only display the no mine icon if they turned mines off *and* there are mines in the chart
local mines = GAMESTATE:Env()["TotalMines" .. pn]
if mines > 0 then table.insert(modnames,"NoMines") end


local af = Def.ActorFrame{}

local xpos = 0
for mod in ivalues(mods) do
    local findmod = FindInTable(mod, modnames)
    if findmod then
        af[#af+1] = Def.Sprite{
            Name = "icon"..mod,
            Texture = "icons 8x1",
            InitCommand = function(self)
                self:animate(false):horizalign(player == PLAYER_1 and "left" or "right"):x(xpos):setstate(findmod - 1)
                xpos = xpos + (player == PLAYER_1 and 33 or -33)
            end
        }
    end
end

return af