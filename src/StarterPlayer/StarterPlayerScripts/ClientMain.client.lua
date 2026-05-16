-- ClientMain.client.lua
-- Точка входа клиентской логики проекта «Златоземье: Своя Земля».
print("[ROJO TEST] ClientMain synced")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local questUpdateEvent = remotes:WaitForChild("QuestUpdateEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestScreenGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local questLabel = Instance.new("TextLabel")
questLabel.Name = "QuestLabel"
questLabel.Size = UDim2.fromOffset(320, 90)
questLabel.Position = UDim2.fromOffset(20, 20)
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

local hideRequestId = 0

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

print(string.format("[GoldenLand] Клиент MVP 0.1 запущен для игрока: %s", localPlayer.Name))
