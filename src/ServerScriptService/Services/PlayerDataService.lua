-- PlayerDataService
-- Загружает, хранит и сохраняет простые профили игроков.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = {}

local profiles = {}
local profileSaveStateByUserId = {}
local PROFILE_STORE_NAME = "GoldenLandPlayerProfiles_v1"
local profileStore = nil
local SAVE_THROTTLE_SECONDS = 10
local DEFAULT_RESOURCE_ZONES = {
	ForestArea_01 = {
		State = "Active",
		RemainingActions = 12,
	},
}

local function createDefaultResourceZones()
	return {
		ForestArea_01 = {
			State = DEFAULT_RESOURCE_ZONES.ForestArea_01.State,
			RemainingActions = DEFAULT_RESOURCE_ZONES.ForestArea_01.RemainingActions,
		},
	}
end

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
		ToolKitLevel = 0,
		ForestUnlocked = false,
		CurrentQuestId = nil,
		CompletedQuests = {},
		QuestProgress = {},
		ResourceZones = createDefaultResourceZones(),
		_Dirty = false,
		_SaveDisabled = false,
	}
end

local function getProfileKey(player)
	return string.format("Player_%d", player.UserId)
end

local function getForestAreaLogValues(profile)
	local forestZone = profile.ResourceZones and profile.ResourceZones.ForestArea_01

	if type(forestZone) ~= "table" then
		return "nil", 0
	end

	return forestZone.State or "nil", forestZone.RemainingActions or 0
end

local function logProfileValues(prefix, profile)
	local forestState, forestRemainingActions = getForestAreaLogValues(profile)

	print(string.format(
		"[PlayerDataService] %s: Gold=%d Wood=%d Stone=%d Metal=%d HouseLevel=%d ToolKitLevel=%d ForestUnlocked=%s ForestArea_01.State=%s RemainingActions=%d",
		prefix,
		profile.Gold or 0,
		profile.Wood or 0,
		profile.Stone or 0,
		profile.Metal or 0,
		profile.HouseLevel or 1,
		profile.ToolKitLevel or 0,
		tostring(profile.ForestUnlocked == true),
		forestState,
		forestRemainingActions
	))
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

local function normalizeResourceZones(savedResourceZones, savedResourceAreas)
	local resourceZones = createDefaultResourceZones()
	local savedForestZone = nil

	if type(savedResourceZones) == "table" and type(savedResourceZones.ForestArea_01) == "table" then
		savedForestZone = savedResourceZones.ForestArea_01
	elseif type(savedResourceAreas) == "table" and type(savedResourceAreas.ForestArea_01) == "table" then
		savedForestZone = savedResourceAreas.ForestArea_01
	end

	if not savedForestZone then
		return resourceZones
	end

	local forestZone = resourceZones.ForestArea_01

	if type(savedForestZone.RemainingActions) == "number" then
		forestZone.RemainingActions = math.clamp(savedForestZone.RemainingActions, 0, DEFAULT_RESOURCE_ZONES.ForestArea_01.RemainingActions)
	elseif type(savedForestZone.Durability) == "number" then
		forestZone.RemainingActions = if savedForestZone.Durability <= 0 then 0 else DEFAULT_RESOURCE_ZONES.ForestArea_01.RemainingActions
	end

	if type(savedForestZone.State) == "string" and savedForestZone.State == "Empty" then
		forestZone.State = "Empty"
		forestZone.RemainingActions = 0
	elseif forestZone.RemainingActions <= 0 then
		forestZone.State = "Empty"
	else
		forestZone.State = "Active"
	end

	return resourceZones
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
	applyNumber(profile, savedProfile, "ToolKitLevel")

	if type(savedProfile.PlotUnlocked) == "boolean" then
		profile.PlotUnlocked = savedProfile.PlotUnlocked
	end

	if type(savedProfile.StorageBuilt) == "boolean" then
		profile.StorageBuilt = savedProfile.StorageBuilt
	end

	if type(savedProfile.WorkshopBuilt) == "boolean" then
		profile.WorkshopBuilt = savedProfile.WorkshopBuilt
	end

	if type(savedProfile.ForestUnlocked) == "boolean" then
		profile.ForestUnlocked = savedProfile.ForestUnlocked
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

	profile.ResourceZones = normalizeResourceZones(savedProfile.ResourceZones, savedProfile.ResourceAreas)

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
		ToolKitLevel = profile.ToolKitLevel,
		ForestUnlocked = profile.ForestUnlocked,
		CurrentQuestId = profile.CurrentQuestId,
		CompletedQuests = copyTable(profile.CompletedQuests),
		QuestProgress = copyTable(profile.QuestProgress),
		ResourceZones = copyTable(profile.ResourceZones),
	}
end

local function loadProfile(player)
	local store = getProfileStore()
	local profileKey = getProfileKey(player)

	print(string.format("[PlayerDataService] Loading profile key: %s", profileKey))

	if not store then
		return nil, true
	end

	local success, result = pcall(function()
		return store:GetAsync(profileKey)
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
		print(string.format("[PlayerDataService] Loaded saved data for %s", player.Name))
		logProfileValues("Loaded profile values", profile)
	elseif loadFailed then
		profile = createDefaultProfile(player)
		profile._SaveDisabled = true
		warn(string.format("[PlayerDataService] Created temporary profile for %s because saved data could not be loaded.", player.Name))
		logProfileValues("Temporary default profile values", profile)
	else
		profile = createDefaultProfile(player)
		print(string.format("[PlayerDataService] No saved data found for %s, using default profile", player.Name))
		logProfileValues("Default profile values", profile)
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

function PlayerDataService.MarkDirty(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false
	end

	profile._Dirty = true
	return true
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
		ToolKitLevel = profile.ToolKitLevel,
		ForestUnlocked = profile.ForestUnlocked,
		ResourceZones = copyTable(profile.ResourceZones),
	}
end

function PlayerDataService.SendProfileUpdate(player)
	local publicProfile = PlayerDataService.GetPublicProfile(player)

	if not publicProfile then
		return false
	end

	getRemoteEvent("PlayerStatsUpdateEvent"):FireClient(player, publicProfile)
	print(string.format(
		"[PlayerDataService] Sent stats update: Gold=%d Wood=%d Stone=%d Metal=%d HouseLevel=%d ToolKitLevel=%d",
		publicProfile.Gold,
		publicProfile.Wood,
		publicProfile.Stone,
		publicProfile.Metal,
		publicProfile.HouseLevel,
		publicProfile.ToolKitLevel
	))
	return true
end

function PlayerDataService.SaveProfile(player, options)
	options = options or {}

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlayerDataService] Save skipped for %s: profile not loaded", player.Name))
		return false
	end

	if profile._SaveDisabled then
		warn(string.format("[PlayerDataService] Save skipped for %s: profile was created after load failure", player.Name))
		return false
	end

	local force = options.Force == true or options.force == true
	local userId = player.UserId
	local saveState = profileSaveStateByUserId[userId] or {}
	profileSaveStateByUserId[userId] = saveState

	if saveState.InProgress then
		print(string.format("[PlayerDataService] Skipped duplicate save for %s", player.Name))
		return false
	end

	local now = os.clock()

	if saveState.LastSaveAt and now - saveState.LastSaveAt < SAVE_THROTTLE_SECONDS then
		if not force or profile._Dirty ~= true then
			print(string.format("[PlayerDataService] Skipped duplicate save for %s", player.Name))
			return false
		end
	end

	if not force and profile._Dirty ~= true then
		print(string.format("[PlayerDataService] Skipped duplicate save for %s", player.Name))
		return false
	end

	local store = getProfileStore()

	if not store then
		warn(string.format("[PlayerDataService] Profile for %s was not saved: DataStore is not available.", player.Name))
		return false
	end

	logProfileValues(string.format("Saving profile for %s", player.Name), profile)

	local saveData = createSaveData(profile)
	saveState.InProgress = true
	local success, result = pcall(function()
		store:SetAsync(getProfileKey(player), saveData)
	end)
	saveState.InProgress = false

	if not success then
		warn(string.format("[PlayerDataService] Failed to save profile for %s: %s", player.Name, tostring(result)))
		return false
	end

	saveState.LastSaveAt = os.clock()
	profile._Dirty = false
	print(string.format("[PlayerDataService] Saved profile for %s.", player.Name))
	PlayerDataService.SendProfileUpdate(player)
	return true
end

function PlayerDataService.RemoveProfile(player)
	local userId = player.UserId

	if profiles[userId] then
		PlayerDataService.SaveProfile(player, { Force = true })
		profiles[userId] = nil
		print(string.format("[PlayerDataService] Removed profile for %s from memory.", player.Name))
	else
		print(string.format("[PlayerDataService] No profile to remove for %s.", player.Name))
	end
end

return PlayerDataService
