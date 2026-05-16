-- CurrencyService
-- Mutates resources in the player's in-memory profile.

local PlayerDataService = require(script.Parent.PlayerDataService)

local CurrencyService = {}

local function addResource(player, resourceName, amount)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[CurrencyService] Profile for %s was not found. %s was not added.", player.Name, resourceName))
		return nil
	end

	profile[resourceName] += amount

	print(string.format(
		"[CurrencyService] Added %d %s to %s. New amount: %d.",
		amount,
		resourceName,
		player.Name,
		profile[resourceName]
	))

	return profile[resourceName]
end

function CurrencyService.AddGold(player, amount)
	return addResource(player, "Gold", amount)
end

function CurrencyService.AddWood(player, amount)
	return addResource(player, "Wood", amount)
end

function CurrencyService.AddStone(player, amount)
	return addResource(player, "Stone", amount)
end

return CurrencyService
