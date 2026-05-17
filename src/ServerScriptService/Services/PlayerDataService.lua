-- PlayerDataService
-- Загружает, хранит и сохраняет простые профили игроков.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = {}

local profiles = {}
local PROFILE_STORE_NAME = "GoldenLandPlayerProfiles_v1"
local profileStore = nil

local function getRemoteEvent(eventName)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")

	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local remoteEvent = remotes:FindFirstChild(eventName)

	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = remotes
	end

	return remoteEvent
end

local function createDefaultProfile(player)
	return {
		UserId = player.UserId,
		Gold = 0,
		Wood = 0,
		Stone = 0,
		Metal = 0,
		HouseLevel = 1,
		PlotUnlocked = false,
		StorageBuilt = false,
		WorkshopBuilt = false,
		CurrentQuestId = nil,
		CompletedQuests = {},
		QuestProgress = {},
	}
end

local function getProfileKey(player)
	return string.format("Player_%d", player.UserId)
end

local function getProfileStore()
	if profileStore then
		return profileStore
	end

	local success, result = pcall(function()
		return DataStoreService:GetDataStore(PROFILE_STORE_NAME)
	end)

	if not success then
		warn(string.format("[PlayerDataService] DataStore is not available: %s", tostring(result)))
		return nil
	end

	profileStore = result
	return profileStore
end

local function copyTable(source)
	local result = {}

	if type(source) ~= "table" then
		return result
	end

	for key, value in pairs(source) do
		if type(value) == "table" then
			result[key] = copyTable(value)
		else
			result[key] = value
		end
	end

	return result
end

local function applyNumber(profile, savedProfile, fieldName)
	if type(savedProfile[fieldName]) == "number" then
		profile[fieldName] = savedProfile[fieldName]
	end
end

local function normalizeLoadedProfile(player, savedProfile)
	local profile = createDefaultProfile(player)

	if type(savedProfile) ~= "table" then
		return profile
	end

	-- Сохраняем только ожидаемые поля, чтобы старые или повреждённые данные не ломали профиль.
	applyNumber(profile, savedProfile, "Gold")
	applyNumber(profile, savedProfile, "Wood")
	applyNumber(profile, savedProfile, "Stone")
	applyNumber(profile, savedProfile, "Metal")
	applyNumber(profile, savedProfile, "HouseLevel")

	if type(savedProfile.PlotUnlocked) == "boolean" then
		profile.PlotUnlocked = savedProfile.PlotUnlocked
	end

	if type(savedProfile.StorageBuilt) == "boolean" then
		profile.StorageBuilt = savedProfile.StorageBuilt
	end

	if type(savedProfile.WorkshopBuilt) == "boolean" then
		profile.WorkshopBuilt = savedProfile.WorkshopBuilt
	end

	if type(savedProfile.CurrentQuestId) == "string" or savedProfile.CurrentQuestId == nil then
		profile.CurrentQuestId = savedProfile.CurrentQuestId
	end

	if type(savedProfile.CompletedQuests) == "table" then
		profile.CompletedQuests = copyTable(savedProfile.CompletedQuests)
	end

	if type(savedProfile.QuestProgress) == "table" then
		profile.QuestProgress = copyTable(savedProfile.QuestProgress)
	end

	return profile
end

local function createSaveData(profile)
	return {
		UserId = profile.UserId,
		Gold = profile.Gold,
		Wood = profile.Wood,
		Stone = profile.Stone,
		Metal = profile.Metal,
		HouseLevel = profile.HouseLevel,
		PlotUnlocked = profile.PlotUnlocked,
		StorageBuilt = profile.StorageBuilt,
		WorkshopBuilt = profile.WorkshopBuilt,
		CurrentQuestId = profile.CurrentQuestId,
		CompletedQuests = copyTable(profile.CompletedQuests),
		QuestProgress = copyTable(profile.QuestProgress),
	}
end

local function loadProfile(player)
	local store = getProfileStore()

	if not store then
		return nil, true
	end

	local success, result = pcall(function()
		return store:GetAsync(getProfileKey(player))
	end)

	if not success then
		warn(string.format("[PlayerDataService] Failed to load profile for %s: %s", player.Name, tostring(result)))
		return nil, true
	end

	if result == nil then
		return nil, false
	end

	return normalizeLoadedProfile(player, result), false
end

function PlayerDataService.CreateProfile(player)
	local userId = player.UserId

	if profiles[userId] then
		print(string.format("[PlayerDataService] Profile for %s is already loaded.", player.Name))
		return profiles[userId]
	end

	local profile, loadFailed = loadProfile(player)

	if profile then
		print(string.format("[PlayerDataService] Loaded saved profile for %s (UserId: %d).", player.Name, userId))
	elseif loadFailed then
		profile = createDefaultProfile(player)
		warn(string.format("[PlayerDataService] Created temporary profile for %s because saved data could not be loaded.", player.Name))
	else
		profile = createDefaultProfile(player)
		print(string.format("[PlayerDataService] Created starter profile for %s (UserId: %d).", player.Name, userId))
	end

	profiles[userId] = profile

	task.defer(function()
		if profiles[userId] and PlayerDataService.SendProfileUpdate then
			PlayerDataService.SendProfileUpdate(player)
		end
	end)

	return profile
end

function PlayerDataService.GetProfile(player)
	return profiles[player.UserId]
end

function PlayerDataService.GetPublicProfile(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return nil
	end

	return {
		Gold = profile.Gold,
		Wood = profile.Wood,
		Stone = profile.Stone,
		Metal = profile.Metal,
		HouseLevel = profile.HouseLevel,
		PlotUnlocked = profile.PlotUnlocked,
		StorageBuilt = profile.StorageBuilt,
		WorkshopBuilt = profile.WorkshopBuilt,
	}
end

function PlayerDataService.SendProfileUpdate(player)
	local publicProfile = PlayerDataService.GetPublicProfile(player)

	if not publicProfile then
		return false
	end

	getRemoteEvent("PlayerStatsUpdateEvent"):FireClient(player, publicProfile)
	print(string.format(
		"[PlayerDataService] Sent stats update: Gold=%d Wood=%d Stone=%d Metal=%d HouseLevel=%d",
		publicProfile.Gold,
		publicProfile.Wood,
		publicProfile.Stone,
		publicProfile.Metal,
		publicProfile.HouseLevel
	))
	return true
end

function PlayerDataService.SaveProfile(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		print(string.format("[PlayerDataService] No profile to save for %s.", player.Name))
		return false
	end

	local store = getProfileStore()

	if not store then
		warn(string.format("[PlayerDataService] Profile for %s was not saved: DataStore is not available.", player.Name))
		return false
	end

	local saveData = createSaveData(profile)
	local success, result = pcall(function()
		store:SetAsync(getProfileKey(player), saveData)
	end)

	if not success then
		warn(string.format("[PlayerDataService] Failed to save profile for %s: %s", player.Name, tostring(result)))
		return false
	end

	print(string.format("[PlayerDataService] Saved profile for %s.", player.Name))
	PlayerDataService.SendProfileUpdate(player)
	return true
end

function PlayerDataService.RemoveProfile(player)
	local userId = player.UserId

	if profiles[userId] then
		PlayerDataService.SaveProfile(player)
		profiles[userId] = nil
		print(string.format("[PlayerDataService] Removed profile for %s from memory.", player.Name))
	else
		print(string.format("[PlayerDataService] No profile to remove for %s.", player.Name))
	end
end

return PlayerDataService
