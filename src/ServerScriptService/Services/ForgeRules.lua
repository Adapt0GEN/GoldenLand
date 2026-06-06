-- ForgeRules
-- Правила кузницы: константы, стоимости, рецепты и валидация.
-- Это односторонний модуль: его требует PlotService, но сам он PlotService не требует.
-- Визуал, промпты, восстановление и Action Preview остаются в PlotService.

local PlayerDataService = require(script.Parent.PlayerDataService)
local CurrencyService = require(script.Parent.CurrencyService)

local ForgeRules = {}

local MAX_FORGE_LEVEL = 2

local FORGE_BUILD_COST = {
	Gold = 10,
	Wood = 20,
	Stone = 30,
	Metal = 15,
}

local FORGE_LEVEL_2_COST = {
	Gold = 25,
	Wood = 20,
	Stone = 20,
	Metal = 15,
	MetalIngot = 5,
	MetalParts = 3,
}

local FORGE_SMELT_RECIPES = {
	[1] = {
		Cost = {
			Metal = 5,
		},
		MetalIngotReward = 1,
		Description = "Металл 5 -> слиток 1",
	},
	[2] = {
		Cost = {
			Metal = 8,
		},
		MetalIngotReward = 2,
		Description = "Металл 8 -> слитки 2",
	},
}

local FORGE_PARTS_COST = {
	MetalIngot = 2,
}

local function getForgeSmeltRecipe(forgeLevel)
	return FORGE_SMELT_RECIPES[forgeLevel]
end

-- Read-only геттеры. Возвращаемые таблицы вызывающий код менять не должен.
function ForgeRules.GetMaxForgeLevel()
	return MAX_FORGE_LEVEL
end

function ForgeRules.GetBuildCost()
	return FORGE_BUILD_COST
end

function ForgeRules.GetLevel2Cost()
	return FORGE_LEVEL_2_COST
end

function ForgeRules.GetSmeltRecipe(forgeLevel)
	return getForgeSmeltRecipe(forgeLevel)
end

function ForgeRules.GetPartsCost()
	return FORGE_PARTS_COST
end

function ForgeRules.CanBuildForge(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "профиль не найден"
	end

	if not profile.PlotUnlocked then
		return false, "участок еще не открыт"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Forge") >= 1 then
		return false, "кузница уже построена"
	end

	if not CurrencyService.CanAfford(player, FORGE_BUILD_COST) then
		return false, "не хватает ресурсов", FORGE_BUILD_COST, CurrencyService.FormatMissingResources(player, FORGE_BUILD_COST)
	end

	return true, "можно построить", FORGE_BUILD_COST
end

function ForgeRules.CanUpgradeForge(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "profile not found"
	end

	local forgeLevel = PlayerDataService.GetBuildingLevel(profile, "Forge")

	if forgeLevel < 1 then
		return false, "forge not built"
	end

	if forgeLevel >= MAX_FORGE_LEVEL then
		return false, "forge already upgraded"
	end

	if not CurrencyService.CanAfford(player, FORGE_LEVEL_2_COST) then
		return false, "not enough resources", FORGE_LEVEL_2_COST, CurrencyService.FormatMissingResources(player, FORGE_LEVEL_2_COST)
	end

	return true, "can upgrade", FORGE_LEVEL_2_COST, nil, forgeLevel + 1
end

function ForgeRules.CanSmeltMetalIngot(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "profile not found"
	end

	local forgeLevel = PlayerDataService.GetBuildingLevel(profile, "Forge")
	local recipe = getForgeSmeltRecipe(forgeLevel)

	if not recipe then
		return false, "forge not built"
	end

	if not CurrencyService.CanAfford(player, recipe.Cost) then
		return false, "not enough resources", recipe.Cost, CurrencyService.FormatMissingResources(player, recipe.Cost)
	end

	return true, "can smelt", recipe.Cost, nil, recipe.MetalIngotReward
end

function ForgeRules.CanMakeMetalParts(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "profile not found"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Forge") < 1 then
		return false, "forge not built"
	end

	if not CurrencyService.CanAfford(player, FORGE_PARTS_COST) then
		return false, "not enough resources", FORGE_PARTS_COST, CurrencyService.FormatMissingResources(player, FORGE_PARTS_COST)
	end

	return true, "can make parts", FORGE_PARTS_COST
end

return ForgeRules
