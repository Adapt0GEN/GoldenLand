<<<<<<< ours
<<<<<<< ours
<<<<<<< ours
-- QuestService.lua
-- Минимальная заглушка сервиса квестов.
-- MVP 0.1 начнётся с простой цепочки заданий от NPC-старосты.

local QuestService = {}

function QuestService.Init()
	print("[QuestService] Инициализация заглушки")
end

function QuestService.GetStartingQuestId()
	return "talk_to_elder"
=======
=======
>>>>>>> theirs
=======
>>>>>>> theirs
-- QuestService
-- Управляет тестовыми квестами и наградами.

local PlayerDataService = require(script.Parent.PlayerDataService)
local CurrencyService = require(script.Parent.CurrencyService)

local QuestService = {}

QuestService.Quests = {
	first_steps = {
		Id = "first_steps",
		Name = "Первые шаги",
		RewardGold = 25,
		RewardWood = 5,
	},
}

function QuestService.StartQuest(player, questId)
	local profile = PlayerDataService.GetProfile(player)
	local quest = QuestService.Quests[questId]

	if not profile then
		warn(string.format("[QuestService] Не найден профиль игрока %s. Квест не начат.", player.Name))
		return false
	end

	if not quest then
		warn(string.format("[QuestService] Квест %s не найден.", tostring(questId)))
		return false
	end

	profile.CurrentQuestId = questId
	print(string.format("[QuestService] Игрок %s начал квест '%s'.", player.Name, quest.Name))

	return true
end

function QuestService.CompleteQuest(player, questId)
	local profile = PlayerDataService.GetProfile(player)
	local quest = QuestService.Quests[questId]

	if not profile then
		warn(string.format("[QuestService] Не найден профиль игрока %s. Квест не завершён.", player.Name))
		return false
	end

	if not quest then
		warn(string.format("[QuestService] Квест %s не найден.", tostring(questId)))
		return false
	end

	if profile.CompletedQuests[questId] then
		print(string.format("[QuestService] Игрок %s уже завершил квест '%s'.", player.Name, quest.Name))
		return false
	end

	profile.CompletedQuests[questId] = true

	if profile.CurrentQuestId == questId then
		profile.CurrentQuestId = nil
	end

	CurrencyService.AddGold(player, quest.RewardGold)
	CurrencyService.AddWood(player, quest.RewardWood)

	print(string.format(
		"[QuestService] Игрок %s завершил квест '%s' и получил награду: %d Gold, %d Wood.",
		player.Name,
		quest.Name,
		quest.RewardGold,
		quest.RewardWood
	))

	return true
<<<<<<< ours
<<<<<<< ours
>>>>>>> theirs
=======
>>>>>>> theirs
=======
>>>>>>> theirs
end

return QuestService
