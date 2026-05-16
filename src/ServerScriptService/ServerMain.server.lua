-- ServerMain
-- Точка входа для первого технического прототипа сервисного ядра GoldenLand.

local Players = game:GetService("Players")

local Services = script.Parent.Services
local PlayerDataService = require(Services.PlayerDataService)
local QuestService = require(Services.QuestService)
local PlotService = require(Services.PlotService)
local CurrencyService = require(Services.CurrencyService)

local function formatCompletedQuests(completedQuests)
	local questIds = {}

	for questId, completed in pairs(completedQuests) do
		if completed then
			table.insert(questIds, questId)
		end
	end

	if #questIds == 0 then
		return "none"
	end

	return table.concat(questIds, ", ")
end

local function printProfile(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ServerMain] Cannot print profile for %s: profile was not found.", player.Name))
		return
	end

	print(string.format("[ServerMain] Final profile for %s:", player.Name))
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
	print(string.format("[ServerMain] Running test sequence for %s.", player.Name))

	QuestService.StartQuest(player, "first_steps")

	task.delay(3, function()
		if not PlayerDataService.GetProfile(player) then
			print(string.format("[ServerMain] %s left before the test sequence finished.", player.Name))
			return
		end

		QuestService.CompleteQuest(player, "first_steps")
		PlotService.UnlockPlot(player)
		PlotService.CreateTestPlot(player)
		PlotService.UpgradeHouse(player)
		CurrencyService.AddStone(player, 3)
		printProfile(player)
	end)
end

local function onPlayerAdded(player)
	print(string.format("[ServerMain] %s joined. Loading player data...", player.Name))
	PlayerDataService.CreateProfile(player)
	print(string.format("[ServerMain] Data for %s is ready.", player.Name))

	runTestSequence(player)
end

local function onPlayerRemoving(player)
	print(string.format("[ServerMain] %s is leaving. Clearing in-memory data...", player.Name))
	PlotService.RemovePlot(player)
	PlayerDataService.RemoveProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

print("[ServerMain] GoldenLand service core started.")
