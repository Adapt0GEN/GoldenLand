-- ServerMain
-- Точка входа для первого RPG-прототипа сервисного ядра GoldenLand.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureQuestUpdateEvent()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")

	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local questUpdateEvent = remotes:FindFirstChild("QuestUpdateEvent")

	if not questUpdateEvent then
		questUpdateEvent = Instance.new("RemoteEvent")
		questUpdateEvent.Name = "QuestUpdateEvent"
		questUpdateEvent.Parent = remotes
	end

	return questUpdateEvent
end

ensureQuestUpdateEvent()

local Services = script.Parent.Services
local PlayerDataService = require(Services.PlayerDataService)
local PlotService = require(Services.PlotService)
local WorldService = require(Services.WorldService)
local NPCService = require(Services.NPCService)
local ResourceService = require(Services.ResourceService)

-- Порядок старта мира: сначала сцена, затем NPC и ресурсы.
WorldService.CreateStartWorld()
NPCService.CreateVillageElder()
ResourceService.CreateResourceNodes()

local function onPlayerAdded(player)
	print(string.format("[ServerMain] %s joined. Loading player data...", player.Name))
	local profile = PlayerDataService.CreateProfile(player)
	print(string.format("[ServerMain] Data for %s is ready.", player.Name))

	if profile.PlotUnlocked then
		-- Если земля уже была открыта в сохранении, восстанавливаем визуальный участок.
		PlotService.CreateTestPlot(player)

		if profile.HouseLevel > 1 then
			print(string.format("[ServerMain] Restored house visual for %s at level %d.", player.Name, profile.HouseLevel))
		end
	end
end

local function onPlayerRemoving(player)
	print(string.format("[ServerMain] %s is leaving. Clearing in-memory data...", player.Name))
	PlotService.RemovePlot(player)
	PlayerDataService.RemoveProfile(player)
end

local function saveAllProfiles()
	print("[ServerMain] Server is closing. Saving player profiles...")

	for _, player in Players:GetPlayers() do
		PlayerDataService.SaveProfile(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
game:BindToClose(saveAllProfiles)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

print("[ServerMain] GoldenLand service core started.")
