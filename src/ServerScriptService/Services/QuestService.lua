-- QuestService
-- Handles the test quest flow and rewards.

local PlayerDataService = require(script.Parent.PlayerDataService)
local CurrencyService = require(script.Parent.CurrencyService)

local QuestService = {}

QuestService.Quests = {
	first_steps = {
		Id = "first_steps",
		Name = "First Steps",
		RewardGold = 25,
		RewardWood = 5,
	},
}

function QuestService.StartQuest(player, questId)
	local profile = PlayerDataService.GetProfile(player)
	local quest = QuestService.Quests[questId]

	if not profile then
		warn(string.format("[QuestService] Profile for %s was not found. Quest was not started.", player.Name))
		return false
	end

	if not quest then
		warn(string.format("[QuestService] Quest %s was not found.", tostring(questId)))
		return false
	end

	profile.CurrentQuestId = questId
	print(string.format("[QuestService] %s started quest '%s'.", player.Name, quest.Name))

	return true
end

function QuestService.CompleteQuest(player, questId)
	local profile = PlayerDataService.GetProfile(player)
	local quest = QuestService.Quests[questId]

	if not profile then
		warn(string.format("[QuestService] Profile for %s was not found. Quest was not completed.", player.Name))
		return false
	end

	if not quest then
		warn(string.format("[QuestService] Quest %s was not found.", tostring(questId)))
		return false
	end

	if profile.CompletedQuests[questId] then
		print(string.format("[QuestService] %s has already completed quest '%s'.", player.Name, quest.Name))
		return false
	end

	profile.CompletedQuests[questId] = true

	if profile.CurrentQuestId == questId then
		profile.CurrentQuestId = nil
	end

	CurrencyService.AddGold(player, quest.RewardGold)
	CurrencyService.AddWood(player, quest.RewardWood)

	print(string.format(
		"[QuestService] %s completed quest '%s' and received %d Gold, %d Wood.",
		player.Name,
		quest.Name,
		quest.RewardGold,
		quest.RewardWood
	))

	return true
end

return QuestService
