-- ClientMain.client.lua
-- Точка входа клиентской логики проекта «Златоземье: Своя Земля».
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local questUpdateEvent = remotes:WaitForChild("QuestUpdateEvent")
local playerStatsUpdateEvent = remotes:WaitForChild("PlayerStatsUpdateEvent")
local playerMessageEvent = remotes:WaitForChild("PlayerMessageEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestScreenGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.fromOffset(260, 135)
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
statsLabel.Text = "Золото: 0\nДерево: 0\nКамень: 0\nМеталл: 0\nДом: уровень 1"
statsLabel.Parent = screenGui

local questLabel = Instance.new("TextLabel")
questLabel.Name = "QuestLabel"
questLabel.Size = UDim2.fromOffset(320, 90)
questLabel.Position = UDim2.fromOffset(20, 170)
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

local hideRequestId = 0
local messageHideRequestId = 0

local function updateStatsUi(data)
	local gold = data.Gold or 0
	local wood = data.Wood or 0
	local stone = data.Stone or 0
	local metal = data.Metal or 0
	local houseLevel = data.HouseLevel or 1

	print(string.format(
		"[ClientMain] Received stats update: Gold=%d Wood=%d Stone=%d Metal=%d HouseLevel=%d",
		gold,
		wood,
		stone,
		metal,
		houseLevel
	))

	statsLabel.Text = string.format(
		"Золото: %d\nДерево: %d\nКамень: %d\nМеталл: %d\nДом: уровень %d",
		gold,
		wood,
		stone,
		metal,
		houseLevel
	)
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

print(string.format("[GoldenLand] Клиент MVP 0.1 запущен для игрока: %s", localPlayer.Name))
