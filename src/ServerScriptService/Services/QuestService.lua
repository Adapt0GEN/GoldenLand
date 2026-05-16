-- QuestService
-- Ведёт простые квесты, прогресс целей и выдачу наград.

local PlayerDataService = require(script.Parent.PlayerDataService)
local CurrencyService = require(script.Parent.CurrencyService)

local QuestService = {}

QuestService.Quests = {
	first_steps = {
		Id = "first_steps",
		Name = "Собери дерево",
		RewardGold = 25,
		RewardWood = 5,
		Objectives = {
			wood_collected = {
				TargetAmount = 3,
			},
		},
	},
}

local function getQuest(questId)
	local quest = QuestService.Quests[questId]

	if not quest then
		warn(string.format("[QuestService] Quest %s was not found.", tostring(questId)))
		return nil
	end

	return quest
end

local function ensureQuestProgress(profile, questId)
	profile.QuestProgress = profile.QuestProgress or {}
	profile.QuestProgress[questId] = profile.QuestProgress[questId] or {}

	return profile.QuestProgress[questId]
end

local function getObjectiveTarget(quest, objectiveId)
	local objective = quest.Objectives and quest.Objectives[objectiveId]

	if not objective then
		return nil
	end

	return objective.TargetAmount
end

function QuestService.StartQuest(player, questId)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[QuestService] Profile for %s was not found. Quest was not started.", player.Name))
		return false
	end

	local quest = getQuest(questId)

	if not quest then
		return false
	end

	if profile.CompletedQuests[questId] then
		print(string.format("[QuestService] %s has already completed quest '%s'.", player.Name, quest.Name))
		return false
	end

	local questProgress = ensureQuestProgress(profile, questId)

	-- Первый квест начинается с нулевого прогресса сбора дерева.
	if questId == "first_steps" then
		questProgress.wood_collected = 0
	end

	profile.CurrentQuestId = questId
	print(string.format("[QuestService] %s started quest '%s'.", player.Name, quest.Name))

	return true
end

function QuestService.AddQuestProgress(player, questId, objectiveId, amount)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[QuestService] Profile for %s was not found. Quest progress was not added.", player.Name))
		return nil
	end

	local quest = getQuest(questId)

	if not quest then
		return nil
	end

	if not getObjectiveTarget(quest, objectiveId) then
		warn(string.format("[QuestService] Objective %s was not found in quest %s.", tostring(objectiveId), questId))
		return nil
	end

	if profile.CompletedQuests[questId] then
		print(string.format("[QuestService] %s has already completed quest '%s'.", player.Name, quest.Name))
		return nil
	end

	if profile.CurrentQuestId ~= questId then
		print(string.format("[QuestService] %s has not started quest '%s' yet.", player.Name, quest.Name))
		return nil
	end

	local questProgress = ensureQuestProgress(profile, questId)
	local currentAmount = questProgress[objectiveId] or 0
	local newAmount = currentAmount + amount

	questProgress[objectiveId] = newAmount

	print(string.format(
		"[QuestService] %s quest '%s' progress %s: %d.",
		player.Name,
		quest.Name,
		objectiveId,
		newAmount
	))

	return newAmount
end

function QuestService.GetQuestProgress(player, questId, objectiveId)
	local profile = PlayerDataService.GetProfile(player)

	if not profile or not profile.QuestProgress then
		return 0
	end

	local questProgress = profile.QuestProgress[questId]

	if not questProgress then
		return 0
	end

	return questProgress[objectiveId] or 0
end

function QuestService.IsQuestReadyToComplete(player, questId)
	local quest = getQuest(questId)

	if not quest then
		return false
	end

	for objectiveId, objective in pairs(quest.Objectives or {}) do
		local progress = QuestService.GetQuestProgress(player, questId, objectiveId)

		if progress < objective.TargetAmount then
			return false
		end
	end

	return true
end

function QuestService.CompleteQuest(player, questId)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[QuestService] Profile for %s was not found. Quest was not completed.", player.Name))
		return false
	end

	local quest = getQuest(questId)

	if not quest then
		return false
	end

	if profile.CompletedQuests[questId] then
		print(string.format("[QuestService] %s has already completed quest '%s'.", player.Name, quest.Name))
		return false
	end

	if not QuestService.IsQuestReadyToComplete(player, questId) then
		local woodProgress = QuestService.GetQuestProgress(player, questId, "wood_collected")
		local woodTarget = getObjectiveTarget(quest, "wood_collected") or 0

		warn(string.format(
			"[QuestService] %s cannot complete quest '%s' yet. Wood progress: %d/%d.",
			player.Name,
			quest.Name,
			woodProgress,
			woodTarget
		))

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
