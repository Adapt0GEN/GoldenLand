-- CurrencyService
-- Меняет ресурсы в профиле игрока и обновляет UI.

local PlayerDataService = require(script.Parent.PlayerDataService)

local CurrencyService = {}

local function printResourceState(player, profile, action)
	print(string.format(
		"[CurrencyService] %s for %s. Gold=%d Wood=%d Stone=%d Metal=%d.",
		action,
		player.Name,
		profile.Gold,
		profile.Wood,
		profile.Stone,
		profile.Metal
	))
end

local function sendProfileUpdate(player)
	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end
end

local function addResource(player, resourceName, amount)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[CurrencyService] Profile for %s was not found. %s was not added.", player.Name, resourceName))
		return nil
	end

	profile[resourceName] += amount
	PlayerDataService.MarkDirty(player)

	print(string.format(
		"[CurrencyService] Added %d %s to %s. New amount: %d.",
		amount,
		resourceName,
		player.Name,
		profile[resourceName]
	))

	printResourceState(player, profile, "Resource totals after add")
	sendProfileUpdate(player)

	return profile[resourceName]
end

function CurrencyService.AddGold(player, amount)
	return addResource(player, "Gold", amount)
end

function CurrencyService.AddWood(player, amount)
	local newAmount = addResource(player, "Wood", amount)

	if newAmount ~= nil then
		print(string.format("[CurrencyService] Wood for %s is now %d.", player.Name, newAmount))
	end

	return newAmount
end

function CurrencyService.AddStone(player, amount)
	return addResource(player, "Stone", amount)
end

function CurrencyService.AddMetal(player, amount)
	return addResource(player, "Metal", amount)
end

function CurrencyService.SpendResources(player, cost)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[CurrencyService] Profile for %s was not found. Resources were not spent.", player.Name))
		return false
	end

	local goldCost = cost.Gold or 0
	local woodCost = cost.Wood or 0
	local stoneCost = cost.Stone or 0
	local metalCost = cost.Metal or 0

	profile.Gold -= goldCost
	profile.Wood -= woodCost
	profile.Stone -= stoneCost
	profile.Metal -= metalCost
	PlayerDataService.MarkDirty(player)

	printResourceState(player, profile, "Resource totals after spend")
	sendProfileUpdate(player)

	return true
end

return CurrencyService
