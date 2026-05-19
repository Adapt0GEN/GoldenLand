-- CurrencyService
-- Меняет ресурсы в профиле игрока и обновляет UI.

local PlayerDataService = require(script.Parent.PlayerDataService)

local CurrencyService = {}

local RESOURCE_ORDER = {
	"Wood",
	"Stone",
	"Metal",
	"Gold",
}

local RESOURCE_LABELS = {
	Gold = "золото",
	Wood = "дерево",
	Stone = "камень",
	Metal = "металл",
}

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

function CurrencyService.FormatCost(cost)
	local parts = {}

	for _, resourceName in ipairs(RESOURCE_ORDER) do
		local amount = if cost then cost[resourceName] or 0 else 0

		if amount > 0 then
			table.insert(parts, string.format("%s %d", RESOURCE_LABELS[resourceName], amount))
		end
	end

	if #parts == 0 then
		return "Стоимость: нет"
	end

	return "Стоимость: " .. table.concat(parts, ", ")
end

function CurrencyService.GetMissingResources(player, cost)
	local profile = PlayerDataService.GetProfile(player)
	local missingResources = {}

	if not profile then
		return missingResources
	end

	for _, resourceName in ipairs(RESOURCE_ORDER) do
		local requiredAmount = if cost then cost[resourceName] or 0 else 0
		local currentAmount = profile[resourceName] or 0
		local missingAmount = requiredAmount - currentAmount

		if missingAmount > 0 then
			table.insert(missingResources, {
				Name = resourceName,
				Label = RESOURCE_LABELS[resourceName],
				Amount = missingAmount,
			})
		end
	end

	return missingResources
end

function CurrencyService.FormatMissingResources(player, cost)
	local missingResources = CurrencyService.GetMissingResources(player, cost)
	local parts = {}

	for _, missingResource in ipairs(missingResources) do
		table.insert(parts, string.format("%s %d", missingResource.Label, missingResource.Amount))
	end

	if #parts == 0 then
		return "Не хватает: нет"
	end

	return "Не хватает: " .. table.concat(parts, ", ")
end

function CurrencyService.CanAfford(player, cost)
	if not PlayerDataService.GetProfile(player) then
		return false
	end

	return #CurrencyService.GetMissingResources(player, cost) == 0
end

function CurrencyService.SpendResources(player, cost)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[CurrencyService] Profile for %s was not found. Resources were not spent.", player.Name))
		return false
	end

	if not CurrencyService.CanAfford(player, cost) then
		local missingResourcesMessage = CurrencyService.FormatMissingResources(player, cost)

		warn(string.format("[CurrencyService] %s cannot spend resources. %s", player.Name, missingResourcesMessage))
		return false, missingResourcesMessage
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
