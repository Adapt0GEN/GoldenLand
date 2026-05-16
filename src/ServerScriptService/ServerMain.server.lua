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
local NPCService = require(Services.NPCService)
local ResourceService = require(Services.ResourceService)

NPCService.CreateVillageElder()
ResourceService.CreateResourceNodes()

local function onPlayerAdded(player)
	print(string.format("[ServerMain] %s joined. Loading player data...", player.Name))
	PlayerDataService.CreateProfile(player)
	print(string.format("[ServerMain] Data for %s is ready.", player.Name))
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
