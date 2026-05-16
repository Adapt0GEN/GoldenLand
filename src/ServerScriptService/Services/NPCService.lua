-- NPCService
-- Создаёт старосту деревни и запускает первый квест через ProximityPrompt.

local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)
local PlotService = require(script.Parent.PlotService)

local NPCService = {}

local ELDER_NAME = "VillageElder"
local ELDER_POSITION = Vector3.new(12, 3, 0)
local QUEST_ID = "first_steps"
local OBJECTIVE_ID = "wood_collected"

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

local function createTextSign(name, text, position, parent)
	local signModel = Instance.new("Model")
	signModel.Name = name
	signModel.Parent = parent

	createPart(
		"LeftPost",
		Vector3.new(0.3, 2.6, 0.3),
		position + Vector3.new(-1.7, -0.8, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	createPart(
		"RightPost",
		Vector3.new(0.3, 2.6, 0.3),
		position + Vector3.new(1.7, -0.8, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	local board = createPart(
		"Board",
		Vector3.new(4.5, 1.4, 0.35),
		position + Vector3.new(0, 0.7, 0),
		Color3.fromRGB(235, 205, 120),
		signModel
	)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TextSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "TextLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(55, 35, 20)
	label.Parent = surfaceGui

	return signModel
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
	print(string.format(
		"  QuestProgress.first_steps.wood_collected: %d",
		QuestService.GetQuestProgress(player, QUEST_ID, OBJECTIVE_ID)
	))
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

local function getWoodTarget()
	return QuestService.Quests[QUEST_ID].Objectives[OBJECTIVE_ID].TargetAmount
end

local function giveLandReward(player, profile)
	PlotService.UnlockPlot(player)
	PlotService.CreateTestPlot(player)
	print(string.format("[NPCService] %s получил землю и дом уровня %d.", player.Name, profile.HouseLevel))
end

local function handleFirstStepsQuest(player, profile)
	if profile.CompletedQuests[QUEST_ID] then
		print(string.format("[NPCService] %s, земля уже выдана.", player.Name))
		return
	end

	if profile.CurrentQuestId ~= QUEST_ID then
		if QuestService.StartQuest(player, QUEST_ID) then
			print("[NPCService] Староста выдал квест: собери 3 дерева")
		end

		return
	end

	local woodProgress = QuestService.GetQuestProgress(player, QUEST_ID, OBJECTIVE_ID)
	local woodTarget = getWoodTarget()

	if woodProgress < woodTarget then
		print(string.format(
			"[NPCService] %s, прогресс квеста: дерево %d/%d.",
			player.Name,
			woodProgress,
			woodTarget
		))
		return
	end

	if QuestService.CompleteQuest(player, QUEST_ID) then
		giveLandReward(player, profile)
	end
end

function NPCService.HandleVillageElderTalk(player)
	local profile = getOrCreateProfile(player)

	if not profile then
		warn(string.format("[NPCService] Could not create profile for %s.", player.Name))
		return
	end

	handleFirstStepsQuest(player, profile)
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

	createTextSign(
		"ElderNameSign",
		"Староста",
		ELDER_POSITION + Vector3.new(0, 1, -4),
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
