<<<<<<< ours
<<<<<<< ours
<<<<<<< ours
-- ServerMain.server.lua
-- Точка входа серверной логики проекта «Златоземье: Своя Земля».
-- Пока файл только безопасно подключает базовые сервисы-заглушки.

local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Services")

local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local QuestService = require(Services:WaitForChild("QuestService"))
local PlotService = require(Services:WaitForChild("PlotService"))
local CurrencyService = require(Services:WaitForChild("CurrencyService"))

PlayerDataService.Init()
QuestService.Init()
PlotService.Init()
CurrencyService.Init()

print("[GoldenLand] Серверное ядро MVP 0.1 инициализировано")
=======
=======
>>>>>>> theirs
=======
>>>>>>> theirs
-- ServerMain
-- Первый технический прототип сервисного ядра проекта "Златоземье: Своя Земля".

local Players = game:GetService("Players")

local Services = script.Parent.Services
local PlayerDataService = require(Services.PlayerDataService)
local QuestService = require(Services.QuestService)
local PlotService = require(Services.PlotService)
-- CurrencyService подключён здесь явно, чтобы сервисное ядро сразу загружало все базовые сервисы.
local CurrencyService = require(Services.CurrencyService)

local function formatCompletedQuests(completedQuests)
	local questIds = {}

	for questId, completed in pairs(completedQuests) do
		if completed then
			table.insert(questIds, questId)
		end
	end

	if #questIds == 0 then
		return "нет"
	end

	return table.concat(questIds, ", ")
end

local function printProfile(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ServerMain] Невозможно вывести профиль игрока %s: профиль не найден.", player.Name))
		return
	end

	print(string.format("[ServerMain] Итоговый профиль игрока %s:", player.Name))
	print(string.format("  UserId: %d", profile.UserId))
	print(string.format("  Gold: %d", profile.Gold))
	print(string.format("  Wood: %d", profile.Wood))
	print(string.format("  Stone: %d", profile.Stone))
	print(string.format("  HouseLevel: %d", profile.HouseLevel))
	print(string.format("  PlotUnlocked: %s", tostring(profile.PlotUnlocked)))
	print(string.format("  CurrentQuestId: %s", tostring(profile.CurrentQuestId)))
	print(string.format("  CompletedQuests: %s", formatCompletedQuests(profile.CompletedQuests)))
end

local function runTestSequence(player)
	print(string.format("[ServerMain] Запускаем тестовую последовательность для игрока %s.", player.Name))

	QuestService.StartQuest(player, "first_steps")

	task.delay(3, function()
		-- Игрок мог выйти за эти 3 секунды, поэтому проверяем профиль перед продолжением теста.
		if not PlayerDataService.GetProfile(player) then
			print(string.format("[ServerMain] Игрок %s вышел до завершения тестовой последовательности.", player.Name))
			return
		end

		QuestService.CompleteQuest(player, "first_steps")
		PlotService.UnlockPlot(player)
		PlotService.UpgradeHouse(player)
		printProfile(player)
	end)
end

local function onPlayerAdded(player)
	print(string.format("[ServerMain] Игрок %s зашёл на сервер. Загружаем данные...", player.Name))
	PlayerDataService.CreateProfile(player)
	print(string.format("[ServerMain] Данные игрока %s готовы к работе.", player.Name))

	-- Переменная используется для явной загрузки CurrencyService в прототипе сервисного ядра.
	if CurrencyService then
		runTestSequence(player)
	end
end

local function onPlayerRemoving(player)
	print(string.format("[ServerMain] Игрок %s выходит с сервера. Очищаем данные из памяти...", player.Name))
	PlayerDataService.RemoveProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Поддержка игроков, которые уже были на сервере при запуске скрипта в Studio.
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

print("[ServerMain] Сервисное ядро Златоземья запущено.")
<<<<<<< ours
<<<<<<< ours
>>>>>>> theirs
=======
>>>>>>> theirs
=======
>>>>>>> theirs
