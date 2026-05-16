-- PlotService
-- Test plot and house progression without spending resources.

local PlayerDataService = require(script.Parent.PlayerDataService)

local PlotService = {}

function PlotService.UnlockPlot(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. Plot was not unlocked.", player.Name))
		return false
	end

	profile.PlotUnlocked = true
	print(string.format("[PlotService] %s unlocked a plot.", player.Name))

	return true
end

function PlotService.UpgradeHouse(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. House was not upgraded.", player.Name))
		return false
	end

	profile.HouseLevel += 1
	print(string.format("[PlotService] %s upgraded house to level %d.", player.Name, profile.HouseLevel))

	return true
end

return PlotService
