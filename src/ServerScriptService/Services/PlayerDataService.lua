<<<<<<< ours
<<<<<<< ours
<<<<<<< ours
-- PlayerDataService.lua
-- Минимальная заглушка сервиса данных игрока.
-- В будущем здесь появится загрузка и сохранение прогресса через DataStore.

local PlayerDataService = {}

local DEFAULT_DATA = {
	Coins = 0,
	HouseLevel = 0,
	HasPlot = false,
	ActiveQuestId = nil,
}

function PlayerDataService.Init()
	print("[PlayerDataService] Инициализация заглушки")
end

function PlayerDataService.GetDefaultData()
	-- Возвращаем копию, чтобы другие сервисы случайно не меняли шаблон.
	return table.clone(DEFAULT_DATA)
=======
=======
>>>>>>> theirs
=======
>>>>>>> theirs
-- PlayerDataService
-- Хранит простые профили игроков в памяти сервера.
-- DataStore пока не используется: данные живут только до перезапуска сервера.

local PlayerDataService = {}

local profiles = {}

local function createDefaultProfile(player)
	return {
		UserId = player.UserId,
		Gold = 0,
		Wood = 0,
		Stone = 0,
		HouseLevel = 1,
		PlotUnlocked = false,
		CurrentQuestId = nil,
		CompletedQuests = {},
	}
end

function PlayerDataService.CreateProfile(player)
	local userId = player.UserId

	if profiles[userId] then
		print(string.format("[PlayerDataService] Профиль игрока %s уже загружен.", player.Name))
		return profiles[userId]
	end

	local profile = createDefaultProfile(player)
	profiles[userId] = profile

	print(string.format("[PlayerDataService] Создан стартовый профиль для игрока %s (UserId: %d).", player.Name, userId))

	return profile
end

function PlayerDataService.GetProfile(player)
	return profiles[player.UserId]
end

function PlayerDataService.RemoveProfile(player)
	local userId = player.UserId

	if profiles[userId] then
		profiles[userId] = nil
		print(string.format("[PlayerDataService] Профиль игрока %s удалён из памяти.", player.Name))
	else
		print(string.format("[PlayerDataService] Нет профиля для удаления у игрока %s.", player.Name))
	end
<<<<<<< ours
<<<<<<< ours
>>>>>>> theirs
=======
>>>>>>> theirs
=======
>>>>>>> theirs
end

return PlayerDataService
