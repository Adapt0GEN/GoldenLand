-- ServerMain
-- Точка входа для первого RPG-прототипа сервисного ядра GoldenLand.

local Players = game:GetService("Players")

local Services = script.Parent.Services
local RemoteService = require(Services.RemoteService)

RemoteService.EnsureRemoteEvent("QuestUpdateEvent")
RemoteService.EnsureRemoteEvent("PlayerStatsUpdateEvent")
RemoteService.EnsureRemoteEvent("PlayerMessageEvent")
RemoteService.EnsureRemoteEvent("ActionPreviewEvent")

local PlayerDataService = require(Services.PlayerDataService)
local PlotService = require(Services.PlotService)
local WorldService = require(Services.WorldService)
local NPCService = require(Services.NPCService)
local ResourceService = require(Services.ResourceService)
local AdminService = require(Services.AdminService)
local CombatService = require(Services.CombatService)

-- Связываем перерисовку визуала леса: ResourceService запрашивает обновление,
-- WorldService владеет визуалом. Так ResourceService не требует WorldService напрямую.
ResourceService.SetForestVisualUpdateCallback(function(player)
	WorldService.UpdateForestAreaVisual(player)
end)

-- Порядок старта мира: сначала сцена, затем NPC и ресурсы.
WorldService.CreateStartWorld()
NPCService.CreateVillageElder()
ResourceService.CreateResourceNodes()
AdminService.Start()
CombatService.Start()

local function onPlayerAdded(player)
	print(string.format("[ServerMain] %s joined. Loading player data...", player.Name))
	local profile = PlayerDataService.CreateProfile(player)
	print(string.format("[ServerMain] Data for %s is ready.", player.Name))
	PlayerDataService.SendProfileUpdate(player)
	WorldService.UpdateForestAccessForPlayer(player)

	task.delay(1, function()
		if PlayerDataService.GetProfile(player) then
			PlayerDataService.SendProfileUpdate(player)
			WorldService.UpdateForestAccessForPlayer(player)
		end
	end)

	if profile.PlotUnlocked then
		-- Если земля уже была открыта в сохранении, восстанавливаем визуальный участок.
		PlotService.CreateTestPlot(player)

		local houseLevel = PlayerDataService.GetBuildingLevel(profile, "House")

		if houseLevel > 1 then
			print(string.format("[ServerMain] Restored house visual for %s at level %d.", player.Name, houseLevel))
		end
	end

	-- Восстанавливаем захваченные игроком лагеря (убираем врагов, ставим визуал захвата).
	CombatService.RestoreCampsForPlayer(player)
end

local function onPlayerRemoving(player)
	print(string.format("[ServerMain] %s is leaving. Clearing in-memory data...", player.Name))
	PlotService.RemovePlot(player)
	PlayerDataService.RemoveProfile(player)
end

local function saveAllProfiles()
	print("[ServerMain] Server is closing. Saving player profiles...")
	PlayerDataService.SaveAllProfiles({ Force = true, Wait = true })
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
game:BindToClose(saveAllProfiles)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

print("[ServerMain] GoldenLand service core started.")
