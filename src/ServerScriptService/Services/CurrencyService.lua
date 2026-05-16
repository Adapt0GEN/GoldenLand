<<<<<<< ours
<<<<<<< ours
<<<<<<< ours
-- CurrencyService.lua
-- Минимальная заглушка сервиса валюты.
-- В будущем все операции с валютой должны проверяться на сервере.

local CurrencyService = {}

function CurrencyService.Init()
	print("[CurrencyService] Инициализация заглушки")
end

function CurrencyService.CanAfford(balance, cost)
	return balance >= cost
=======
=======
>>>>>>> theirs
=======
>>>>>>> theirs
-- CurrencyService
-- Изменяет игровые ресурсы в in-memory профиле игрока.

local PlayerDataService = require(script.Parent.PlayerDataService)

local CurrencyService = {}

local function addResource(player, resourceName, amount)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[CurrencyService] Не найден профиль игрока %s. Ресурс %s не начислен.", player.Name, resourceName))
		return nil
	end

	profile[resourceName] += amount

	print(string.format(
		"[CurrencyService] Игроку %s начислено %d %s. Теперь: %d.",
		player.Name,
		amount,
		resourceName,
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
<<<<<<< ours
<<<<<<< ours
>>>>>>> theirs
=======
>>>>>>> theirs
=======
>>>>>>> theirs
end

return CurrencyService
