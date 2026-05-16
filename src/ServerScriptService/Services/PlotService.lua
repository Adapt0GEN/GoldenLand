<<<<<<< ours
<<<<<<< ours
<<<<<<< ours
-- PlotService.lua
-- Минимальная заглушка сервиса личных участков.
-- Позже сервис будет выдавать землю, создавать дом и управлять улучшениями.

local PlotService = {}

local MAX_HOUSE_LEVEL = 3

function PlotService.Init()
	print("[PlotService] Инициализация заглушки")
end

function PlotService.GetMaxHouseLevel()
	return MAX_HOUSE_LEVEL
=======
=======
>>>>>>> theirs
=======
>>>>>>> theirs
-- PlotService
-- Тестовая логика участка и дома без списания ресурсов.

local PlayerDataService = require(script.Parent.PlayerDataService)

local PlotService = {}

function PlotService.UnlockPlot(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Не найден профиль игрока %s. Участок не разблокирован.", player.Name))
		return false
	end

	profile.PlotUnlocked = true
	print(string.format("[PlotService] Игрок %s разблокировал участок.", player.Name))

	return true
end

function PlotService.UpgradeHouse(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Не найден профиль игрока %s. Дом не улучшен.", player.Name))
		return false
	end

	profile.HouseLevel += 1
	print(string.format("[PlotService] Дом игрока %s улучшен до уровня %d.", player.Name, profile.HouseLevel))

	return true
<<<<<<< ours
<<<<<<< ours
>>>>>>> theirs
=======
>>>>>>> theirs
=======
>>>>>>> theirs
end

return PlotService
