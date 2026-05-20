-- ClientMain.client.lua
-- Точка входа клиентской логики проекта «Златоземье: Своя Земля».
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local questUpdateEvent = remotes:WaitForChild("QuestUpdateEvent")
local playerStatsUpdateEvent = remotes:WaitForChild("PlayerStatsUpdateEvent")
local playerMessageEvent = remotes:WaitForChild("PlayerMessageEvent")
local actionPreviewEvent = remotes:WaitForChild("ActionPreviewEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestScreenGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.fromOffset(280, 245)
statsLabel.Position = UDim2.fromOffset(20, 20)
statsLabel.BackgroundColor3 = Color3.fromRGB(28, 34, 30)
statsLabel.BackgroundTransparency = 0.12
statsLabel.BorderSizePixel = 0
statsLabel.TextColor3 = Color3.fromRGB(230, 255, 220)
statsLabel.TextSize = 19
statsLabel.Font = Enum.Font.SourceSansBold
statsLabel.TextWrapped = true
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Center
statsLabel.Text = "Золото: 0\nДерево: 0\nКамень: 0\nМеталл: 0\nДом: уровень 1\nИнструменты: нет\nКузница: уровень 0"
statsLabel.Text = statsLabel.Text .. "\nСлитки: 0"
statsLabel.Text = statsLabel.Text .. "\nДетали: 0"
statsLabel.Text = statsLabel.Text .. "\nСклад: уровень 0"
statsLabel.Parent = screenGui

local questLabel = Instance.new("TextLabel")
questLabel.Name = "QuestLabel"
questLabel.Size = UDim2.fromOffset(320, 90)
questLabel.Position = UDim2.fromOffset(20, 255)
questLabel.BackgroundColor3 = Color3.fromRGB(35, 30, 24)
questLabel.BackgroundTransparency = 0.15
questLabel.BorderSizePixel = 0
questLabel.TextColor3 = Color3.fromRGB(255, 240, 200)
questLabel.TextSize = 20
questLabel.Font = Enum.Font.SourceSansBold
questLabel.TextWrapped = true
questLabel.TextXAlignment = Enum.TextXAlignment.Left
questLabel.TextYAlignment = Enum.TextYAlignment.Center
questLabel.Visible = false
questLabel.Parent = screenGui

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.fromOffset(420, 50)
messageLabel.Position = UDim2.new(0.5, -210, 0, 20)
messageLabel.BackgroundColor3 = Color3.fromRGB(45, 35, 30)
messageLabel.BackgroundTransparency = 0.1
messageLabel.BorderSizePixel = 0
messageLabel.TextColor3 = Color3.fromRGB(255, 230, 190)
messageLabel.TextSize = 20
messageLabel.Font = Enum.Font.SourceSansBold
messageLabel.TextWrapped = true
messageLabel.Visible = false
messageLabel.Parent = screenGui

local actionPreviewFrame = Instance.new("Frame")
actionPreviewFrame.Name = "ActionPreviewFrame"
actionPreviewFrame.Size = UDim2.fromOffset(330, 230)
actionPreviewFrame.Position = UDim2.new(1, -350, 0, 20)
actionPreviewFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 34)
actionPreviewFrame.BackgroundTransparency = 0.08
actionPreviewFrame.BorderSizePixel = 0
actionPreviewFrame.Visible = false
actionPreviewFrame.Parent = screenGui

local actionPreviewTitle = Instance.new("TextLabel")
actionPreviewTitle.Name = "ActionPreviewTitle"
actionPreviewTitle.Size = UDim2.new(1, -20, 0, 34)
actionPreviewTitle.Position = UDim2.fromOffset(10, 8)
actionPreviewTitle.BackgroundTransparency = 1
actionPreviewTitle.TextColor3 = Color3.fromRGB(255, 235, 180)
actionPreviewTitle.TextSize = 20
actionPreviewTitle.Font = Enum.Font.SourceSansBold
actionPreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
actionPreviewTitle.TextYAlignment = Enum.TextYAlignment.Center
actionPreviewTitle.Text = ""
actionPreviewTitle.Parent = actionPreviewFrame

local actionPreviewBody = Instance.new("TextLabel")
actionPreviewBody.Name = "ActionPreviewBody"
actionPreviewBody.Size = UDim2.new(1, -20, 1, -52)
actionPreviewBody.Position = UDim2.fromOffset(10, 44)
actionPreviewBody.BackgroundTransparency = 1
actionPreviewBody.TextColor3 = Color3.fromRGB(230, 235, 230)
actionPreviewBody.TextSize = 17
actionPreviewBody.Font = Enum.Font.SourceSans
actionPreviewBody.TextWrapped = true
actionPreviewBody.TextXAlignment = Enum.TextXAlignment.Left
actionPreviewBody.TextYAlignment = Enum.TextYAlignment.Top
actionPreviewBody.Text = ""
actionPreviewBody.Parent = actionPreviewFrame

local hideRequestId = 0
local messageHideRequestId = 0
local currentPreviewPromptName = nil
local previewPromptNames = {
	HouseUpgradePrompt = true,
	CraftToolKitPrompt = true,
	BuildForgePrompt = true,
	SmeltMetalIngotPrompt = true,
	MakeMetalPartsPrompt = true,
	StorageUpgradePrompt = true,
}
local previewResources = {
	{
		key = "Wood",
		label = "Дерево",
	},
	{
		key = "Stone",
		label = "Камень",
	},
	{
		key = "Metal",
		label = "Металл",
	},
	{
		key = "MetalIngot",
		label = "Слитки",
	},
	{
		key = "MetalParts",
		label = "Детали",
	},
	{
		key = "Gold",
		label = "Золото",
	},
}

local function updateStatsUi(data)
	local gold = data.Gold or 0
	local wood = data.Wood or 0
	local stone = data.Stone or 0
	local metal = data.Metal or 0
	local metalIngot = data.MetalIngot or 0
	local metalParts = data.MetalParts or 0
	local houseLevel = data.HouseLevel or 1
	local storageLevel = data.StorageLevel or 0
	local toolKitLevel = data.ToolKitLevel or 0
	local forgeLevel = data.ForgeLevel or 0
	local toolKitText = "нет"

	if toolKitLevel >= 1 then
		toolKitText = string.format("уровень %d", toolKitLevel)
	end

	print(string.format(
		"[ClientMain] Received stats update: Gold=%d Wood=%d Stone=%d Metal=%d MetalIngot=%d MetalParts=%d HouseLevel=%d StorageLevel=%d ToolKitLevel=%d ForgeLevel=%d",
		gold,
		wood,
		stone,
		metal,
		metalIngot,
		metalParts,
		houseLevel,
		storageLevel,
		toolKitLevel,
		forgeLevel
	))

	statsLabel.Text = string.format(
		"Золото: %d\nДерево: %d\nКамень: %d\nМеталл: %d\nДом: уровень %d\nИнструменты: %s\nКузница: уровень %d",
		gold,
		wood,
		stone,
		metal,
		houseLevel,
		toolKitText,
		forgeLevel
	)
	statsLabel.Text = statsLabel.Text .. string.format("\nСлитки: %d", metalIngot)
	statsLabel.Text = statsLabel.Text .. string.format("\nДетали: %d", metalParts)
	statsLabel.Text = statsLabel.Text .. string.format("\nСклад: уровень %d", storageLevel)

	if currentPreviewPromptName then
		actionPreviewEvent:FireServer({
			action = "show",
			promptName = currentPreviewPromptName,
		})
	end
end

local function showPlayerMessage(message)
	messageHideRequestId += 1
	local currentRequestId = messageHideRequestId

	messageLabel.Text = tostring(message)
	messageLabel.Visible = true

	task.delay(3, function()
		if currentRequestId == messageHideRequestId then
			messageLabel.Visible = false
		end
	end)
end

local function getResourceAmount(resourceTable, resourceName)
	if type(resourceTable) ~= "table" then
		return 0
	end

	return resourceTable[resourceName] or 0
end

local function updateActionPreview(data)
	if type(data) ~= "table" or data.visible ~= true then
		actionPreviewFrame.Visible = false
		return
	end

	local lines = {}

	if data.description and data.description ~= "" then
		table.insert(lines, tostring(data.description))
	end

	table.insert(lines, data.canAfford and "Ресурсов хватает" or "Не хватает ресурсов")
	table.insert(lines, "")

	for _, resource in ipairs(previewResources) do
		local currentAmount = getResourceAmount(data.current, resource.key)
		local requiredAmount = getResourceAmount(data.cost, resource.key)
		local missingAmount = getResourceAmount(data.missing, resource.key)
		local line = string.format("%s: %d / %d", resource.label, currentAmount, requiredAmount)

		if missingAmount > 0 then
			line = string.format("%s (не хватает %d)", line, missingAmount)
		end

		table.insert(lines, line)
	end

	actionPreviewTitle.Text = tostring(data.title or "Действие")
	actionPreviewBody.Text = table.concat(lines, "\n")
	actionPreviewFrame.BackgroundColor3 = if data.canAfford then Color3.fromRGB(30, 42, 34) else Color3.fromRGB(45, 34, 30)
	actionPreviewFrame.Visible = true
end

local function setQuestText(text)
	questLabel.Text = text
	questLabel.Visible = true
end

local function hideQuestAfterDelay(seconds)
	hideRequestId += 1
	local currentRequestId = hideRequestId

	task.delay(seconds, function()
		if currentRequestId == hideRequestId then
			questLabel.Visible = false
		end
	end)
end

local function updateQuestUi(data)
	local title = data.title or "Первые шаги"
	local objectiveText = data.objectiveText or "Собери дерево"
	local current = data.current or 0
	local required = data.required or 0

	if data.status == "completed" then
		setQuestText("Квест завершён")
		hideQuestAfterDelay(4)
		return
	end

	hideRequestId += 1

	if data.status == "ready" then
		setQuestText(string.format("Квест: %s\nВернитесь к старосте", title))
		return
	end

	if data.status == "active" then
		setQuestText(string.format("Квест: %s\n%s: %d/%d", title, objectiveText, current, required))
	end
end

questUpdateEvent.OnClientEvent:Connect(updateQuestUi)
playerStatsUpdateEvent.OnClientEvent:Connect(updateStatsUi)
playerMessageEvent.OnClientEvent:Connect(showPlayerMessage)
actionPreviewEvent.OnClientEvent:Connect(updateActionPreview)

ProximityPromptService.PromptShown:Connect(function(prompt)
	if previewPromptNames[prompt.Name] then
		currentPreviewPromptName = prompt.Name
		actionPreviewEvent:FireServer({
			action = "show",
			promptName = prompt.Name,
		})
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if previewPromptNames[prompt.Name] then
		if currentPreviewPromptName == prompt.Name then
			currentPreviewPromptName = nil
		end

		actionPreviewEvent:FireServer({
			action = "hide",
			promptName = prompt.Name,
		})
	end
end)

print(string.format("[GoldenLand] Клиент MVP 0.1 запущен для игрока: %s", localPlayer.Name))
