-- NPCService
-- Создаёт старосту деревни и запускает первый квест через ProximityPrompt.

local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)
local PlotService = require(script.Parent.PlotService)

local NPCService = {}

local ELDER_NAME = "VillageElder"
local ELDER_POSITION = Vector3.new(10, 3, 10)

local function createPart(name, size, position, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

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
		warn(string.format("[NPCService] Cannot print profile for %s: profile was not found.", player.Name))
		return
	end

	print(string.format("[NPCService] Final profile for %s:", player.Name))
	print(string.format("  UserId: %d", profile.UserId))
	print(string.format("  Gold: %d", profile.Gold))
	print(string.format("  Wood: %d", profile.Wood))
	print(string.format("  Stone: %d", profile.Stone))
	print(string.format("  HouseLevel: %d", profile.HouseLevel))
	print(string.format("  PlotUnlocked: %s", tostring(profile.PlotUnlocked)))
	print(string.format("  CurrentQuestId: %s", tostring(profile.CurrentQuestId)))
	print(string.format("  CompletedQuests: %s", formatCompletedQuests(profile.CompletedQuests)))
end

local function getOrCreateProfile(player)
	local profile = PlayerDataService.GetProfile(player)

	if profile then
		return profile
	end

	print(string.format("[NPCService] Profile for %s was not found. Creating it now.", player.Name))
	return PlayerDataService.CreateProfile(player)
end

local function completeFirstSteps(player, profile)
	if profile.CompletedQuests.first_steps then
		print(string.format("[NPCService] %s has already completed first_steps.", player.Name))
		return false
	end

	-- Первый ручной RPG-сценарий: староста выдаёт и сразу закрывает тестовый квест.
	QuestService.StartQuest(player, "first_steps")

	if not QuestService.CompleteQuest(player, "first_steps") then
		return false
	end

	PlotService.UnlockPlot(player)
	PlotService.CreateTestPlot(player)

	if profile.HouseLevel < 2 then
		PlotService.UpgradeHouse(player)
	end

	return true
end

function NPCService.HandleVillageElderTalk(player)
	local profile = getOrCreateProfile(player)

	if not profile then
		warn(string.format("[NPCService] Could not create profile for %s.", player.Name))
		return
	end

	completeFirstSteps(player, profile)
	printProfile(player)
end

function NPCService.CreateVillageElder()
	local existingElder = Workspace:FindFirstChild(ELDER_NAME)

	if existingElder then
		print("[NPCService] Village elder already exists.")
		return existingElder
	end

	local elderModel = Instance.new("Model")
	elderModel.Name = ELDER_NAME
	elderModel.Parent = Workspace

	-- Простая фигура старосты без внешних ассетов.
	local body = createPart(
		"Body",
		Vector3.new(3, 4, 2),
		ELDER_POSITION,
		Color3.fromRGB(110, 80, 55),
		elderModel
	)

	createPart(
		"Head",
		Vector3.new(2, 2, 2),
		ELDER_POSITION + Vector3.new(0, 3, 0),
		Color3.fromRGB(220, 180, 140),
		elderModel
	)

	createPart(
		"Hat",
		Vector3.new(2.6, 0.5, 2.6),
		ELDER_POSITION + Vector3.new(0, 4.25, 0),
		Color3.fromRGB(75, 55, 35),
		elderModel
	)

	createPart(
		"Staff",
		Vector3.new(0.35, 5, 0.35),
		ELDER_POSITION + Vector3.new(2.2, 0.5, -0.2),
		Color3.fromRGB(95, 60, 35),
		elderModel
	)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Поговорить"
	prompt.ObjectText = "Староста"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	prompt.Triggered:Connect(function(player)
		NPCService.HandleVillageElderTalk(player)
	end)

	elderModel.PrimaryPart = body

	print("[NPCService] Village elder created.")
	return elderModel
end

return NPCService
