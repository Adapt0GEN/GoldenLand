-- PlayerDataService
-- Загружает, хранит и сохраняет простые профили игроков.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = {}

local profiles = {}
local profileSaveStateByUserId = {}
local PROFILE_STORE_NAME = "GoldenLandPlayerProfiles_v1"
local profileStore = nil
local SAVE_THROTTLE_SECONDS = 10
local DEFAULT_RESOURCE_ZONES = {
	ForestArea_01 = {
		Type = "ForestArea",
		State = "Active",
		RemainingActions = 12,
		Objects = {
			ForestTreeCluster = {
				Type = "TreeCluster",
				State = "Active",
				Resource = "Wood",
				RemainingActions = 12,
				AmountPerAction = 1,
			},
			ForestStone_01 = {
				Type = "StoneNode",
				State = "Active",
				Resource = "Stone",
				RemainingActions = 1,
				AmountPerAction = 2,
			},
			ForestStone_02 = {
				Type = "StoneNode",
				State = "Active",
				Resource = "Stone",
				RemainingActions = 1,
				AmountPerAction = 2,
			},
		},
	},
}

local function createDefaultResourceZones()
	return {
		ForestArea_01 = {
			Type = DEFAULT_RESOURCE_ZONES.ForestArea_01.Type,
			State = DEFAULT_RESOURCE_ZONES.ForestArea_01.State,
			RemainingActions = DEFAULT_RESOURCE_ZONES.ForestArea_01.RemainingActions,
			Objects = {
				ForestTreeCluster = {
					Type = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestTreeCluster.Type,
					State = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestTreeCluster.State,
					Resource = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestTreeCluster.Resource,
					RemainingActions = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestTreeCluster.RemainingActions,
					AmountPerAction = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestTreeCluster.AmountPerAction,
				},
				ForestStone_01 = {
					Type = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_01.Type,
					State = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_01.State,
					Resource = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_01.Resource,
					RemainingActions = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_01.RemainingActions,
					AmountPerAction = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_01.AmountPerAction,
				},
				ForestStone_02 = {
					Type = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_02.Type,
					State = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_02.State,
					Resource = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_02.Resource,
					RemainingActions = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_02.RemainingActions,
					AmountPerAction = DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_02.AmountPerAction,
				},
			},
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
		MetalIngot = 0,
		HouseLevel = 1,
		PlotUnlocked = false,
		StorageBuilt = false,
		WorkshopBuilt = false,
		ToolKitLevel = 0,
		ForgeLevel = 0,
		ForestUnlocked = false,
		RockZoneUnlocked = false,
		ForestZoneState = "Locked",
		ForestZoneClearedObjects = {},
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

local function getProfileKeyFromUserId(userId)
	return string.format("Player_%d", userId)
end

local function getForestAreaLogValues(profile)
	local forestZone = profile.ResourceZones and profile.ResourceZones.ForestArea_01

	if type(forestZone) ~= "table" then
		return "nil", 0, "nil", "nil"
	end

	local objects = forestZone.Objects or {}
	local treeCluster = objects.ForestTreeCluster or {}
	local forestStone01 = objects.ForestStone_01 or {}
	local forestStone02 = objects.ForestStone_02 or {}

	return forestZone.State or "nil",
		treeCluster.RemainingActions or forestZone.RemainingActions or 0,
		forestStone01.State or "nil",
		forestStone02.State or "nil"
end

local function logProfileValues(prefix, profile)
	local forestState, forestTreeRemainingActions, forestStone01State, forestStone02State = getForestAreaLogValues(profile)

	print(string.format(
		"[PlayerDataService] %s: Gold=%d Wood=%d Stone=%d Metal=%d MetalIngot=%d HouseLevel=%d ToolKitLevel=%d ForgeLevel=%d ForestUnlocked=%s ForestZoneState=%s ForestArea_01.State=%s ForestTreeCluster.RemainingActions=%d ForestStone_01.State=%s ForestStone_02.State=%s",
		prefix,
		profile.Gold or 0,
		profile.Wood or 0,
		profile.Stone or 0,
		profile.Metal or 0,
		profile.MetalIngot or 0,
		profile.HouseLevel or 1,
		profile.ToolKitLevel or 0,
		profile.ForgeLevel or 0,
		tostring(profile.ForestUnlocked == true),
		profile.ForestZoneState or "nil",
		forestState,
		forestTreeRemainingActions,
		forestStone01State,
		forestStone02State
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

local function isResourceObjectActive(resourceObject)
	if type(resourceObject) ~= "table" then
		return false
	end

	return resourceObject.State ~= "Empty" and (resourceObject.RemainingActions or 0) > 0
end

local function normalizeForestObject(resourceObject, defaultObject, maxRemainingActions)
	resourceObject.Type = resourceObject.Type or defaultObject.Type
	resourceObject.State = resourceObject.State or defaultObject.State
	resourceObject.Resource = resourceObject.Resource or defaultObject.Resource
	resourceObject.AmountPerAction = resourceObject.AmountPerAction or defaultObject.AmountPerAction
	resourceObject.RemainingActions = math.clamp(
		resourceObject.RemainingActions or defaultObject.RemainingActions,
		0,
		maxRemainingActions
	)
	resourceObject.State = if resourceObject.State == "Empty" or resourceObject.RemainingActions <= 0 then "Empty" else "Active"
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
	forestZone.Type = "ForestArea"
	forestZone.Objects = forestZone.Objects or {}

	if type(savedForestZone.Objects) == "table" then
		for objectId, savedObject in pairs(savedForestZone.Objects) do
			if type(savedObject) == "table" then
				forestZone.Objects[objectId] = forestZone.Objects[objectId] or {}

				for key, value in pairs(savedObject) do
					forestZone.Objects[objectId][key] = value
				end
			end
		end
	end

	if type(savedForestZone.RemainingActions) == "number" then
		forestZone.RemainingActions = math.clamp(savedForestZone.RemainingActions, 0, DEFAULT_RESOURCE_ZONES.ForestArea_01.RemainingActions)
	elseif type(savedForestZone.Durability) == "number" then
		forestZone.RemainingActions = if savedForestZone.Durability <= 0 then 0 else DEFAULT_RESOURCE_ZONES.ForestArea_01.RemainingActions
	end

	local treeCluster = forestZone.Objects.ForestTreeCluster

	if type(savedForestZone.Objects) ~= "table" or type(savedForestZone.Objects.ForestTreeCluster) ~= "table" then
		treeCluster.RemainingActions = forestZone.RemainingActions
	end

	normalizeForestObject(
		treeCluster,
		DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestTreeCluster,
		DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestTreeCluster.RemainingActions
	)
	normalizeForestObject(
		forestZone.Objects.ForestStone_01,
		DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_01,
		DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_01.RemainingActions
	)
	normalizeForestObject(
		forestZone.Objects.ForestStone_02,
		DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_02,
		DEFAULT_RESOURCE_ZONES.ForestArea_01.Objects.ForestStone_02.RemainingActions
	)

	if isResourceObjectActive(treeCluster)
		or isResourceObjectActive(forestZone.Objects.ForestStone_01)
		or isResourceObjectActive(forestZone.Objects.ForestStone_02)
	then
		forestZone.State = "Active"
	else
		forestZone.State = "Empty"
	end

	forestZone.RemainingActions = treeCluster.RemainingActions

	return resourceZones
end

local function normalizeForestZoneState(savedProfile, profile)
	if profile.ForestUnlocked ~= true then
		return "Locked"
	end

	if savedProfile.ForestZoneState == "Empty" then
		return "Empty"
	elseif savedProfile.ForestZoneState == "Active" then
		return "Active"
	end

	local forestArea = profile.ResourceZones and profile.ResourceZones.ForestArea_01

	if type(forestArea) == "table" and forestArea.State == "Empty" then
		return "Empty"
	end

	return "Active"
end

local function normalizeForestZoneClearedObjects(savedProfile, profile)
	local clearedObjects = {}

	if type(savedProfile.ForestZoneClearedObjects) == "table" then
		for objectId, isCleared in pairs(savedProfile.ForestZoneClearedObjects) do
			if isCleared == true then
				clearedObjects[objectId] = true
			end
		end
	end

	local forestArea = profile.ResourceZones and profile.ResourceZones.ForestArea_01
	local objects = if type(forestArea) == "table" then forestArea.Objects else nil

	if type(objects) == "table" then
		for objectId, resourceObject in pairs(objects) do
			if type(resourceObject) == "table"
				and (resourceObject.State == "Empty" or (resourceObject.RemainingActions or 0) <= 0)
			then
				clearedObjects[objectId] = true
			end
		end
	end

	return clearedObjects
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
	applyNumber(profile, savedProfile, "MetalIngot")
	applyNumber(profile, savedProfile, "HouseLevel")
	applyNumber(profile, savedProfile, "ToolKitLevel")
	applyNumber(profile, savedProfile, "ForgeLevel")

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

	if type(savedProfile.RockZoneUnlocked) == "boolean" then
		profile.RockZoneUnlocked = savedProfile.RockZoneUnlocked
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
	profile.ForestZoneState = normalizeForestZoneState(savedProfile, profile)
	profile.ForestZoneClearedObjects = normalizeForestZoneClearedObjects(savedProfile, profile)

	return profile
end

local function createSaveData(profile)
	return {
		UserId = profile.UserId,
		Gold = profile.Gold,
		Wood = profile.Wood,
		Stone = profile.Stone,
		Metal = profile.Metal,
		MetalIngot = profile.MetalIngot,
		HouseLevel = profile.HouseLevel,
		PlotUnlocked = profile.PlotUnlocked,
		StorageBuilt = profile.StorageBuilt,
		WorkshopBuilt = profile.WorkshopBuilt,
		ToolKitLevel = profile.ToolKitLevel,
		ForgeLevel = profile.ForgeLevel,
		ForestUnlocked = profile.ForestUnlocked,
		RockZoneUnlocked = profile.RockZoneUnlocked,
		ForestZoneState = profile.ForestZoneState,
		ForestZoneClearedObjects = copyTable(profile.ForestZoneClearedObjects),
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
	profile._DirtyRevision = (profile._DirtyRevision or 0) + 1
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
		MetalIngot = profile.MetalIngot,
		HouseLevel = profile.HouseLevel,
		PlotUnlocked = profile.PlotUnlocked,
		StorageBuilt = profile.StorageBuilt,
		WorkshopBuilt = profile.WorkshopBuilt,
		ToolKitLevel = profile.ToolKitLevel,
		ForgeLevel = profile.ForgeLevel,
		ForestUnlocked = profile.ForestUnlocked,
		RockZoneUnlocked = profile.RockZoneUnlocked,
		ForestZoneState = profile.ForestZoneState,
		ForestZoneClearedObjects = copyTable(profile.ForestZoneClearedObjects),
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
		"[PlayerDataService] Sent stats update: Gold=%d Wood=%d Stone=%d Metal=%d MetalIngot=%d HouseLevel=%d ToolKitLevel=%d ForgeLevel=%d",
		publicProfile.Gold,
		publicProfile.Wood,
		publicProfile.Stone,
		publicProfile.Metal,
		publicProfile.MetalIngot,
		publicProfile.HouseLevel,
		publicProfile.ToolKitLevel,
		publicProfile.ForgeLevel
	))
	return true
end

local function saveProfileData(userId, playerName, profile, playerForUpdate, options)
	options = options or {}

	if not profile then
		warn(string.format("[PlayerDataService] Save skipped for %s: profile not loaded", playerName))
		return false
	end

	if profiles[userId] ~= profile then
		return true
	end

	if profile._SaveDisabled then
		warn(string.format("[PlayerDataService] Save skipped for %s: profile was created after load failure", playerName))
		return false
	end

	local force = options.Force == true or options.force == true
	local saveState = profileSaveStateByUserId[userId] or {}
	profileSaveStateByUserId[userId] = saveState

	if saveState.InProgress then
		if not force then
			print(string.format("[PlayerDataService] Skipped duplicate save for %s", playerName))
			return false
		end

		while saveState.InProgress do
			task.wait(0.05)
		end

		if profiles[userId] ~= profile then
			return true
		end

		if profile._Dirty ~= true then
			return true
		end
	end

	local now = os.clock()

	if not force and saveState.LastSaveAt and now - saveState.LastSaveAt < SAVE_THROTTLE_SECONDS then
		print(string.format("[PlayerDataService] Skipped duplicate save for %s", playerName))
		return false
	end

	if not force and profile._Dirty ~= true then
		print(string.format("[PlayerDataService] Skipped duplicate save for %s", playerName))
		return false
	end

	local store = getProfileStore()

	if not store then
		warn(string.format("[PlayerDataService] Profile for %s was not saved: DataStore is not available.", playerName))
		return false
	end

	local saveData = createSaveData(profile)
	local savedDirtyRevision = profile._DirtyRevision or 0
	saveState.InProgress = true
	logProfileValues(string.format("Saving profile for %s", playerName), profile)

	local success, result = pcall(function()
		store:SetAsync(getProfileKeyFromUserId(userId), saveData)
	end)

	saveState.InProgress = false

	if not success then
		warn(string.format("[PlayerDataService] Failed to save profile for %s: %s", playerName, tostring(result)))
		return false
	end

	saveState.LastSaveAt = os.clock()

	if (profile._DirtyRevision or 0) == savedDirtyRevision then
		profile._Dirty = false
	end

	print(string.format("[PlayerDataService] Saved profile for %s.", playerName))

	if playerForUpdate and playerForUpdate.Parent then
		PlayerDataService.SendProfileUpdate(playerForUpdate)
	end

	return true
end

function PlayerDataService.SaveProfile(player, options)
	local profile = PlayerDataService.GetProfile(player)

	return saveProfileData(player.UserId, player.Name, profile, player, options)
end

function PlayerDataService.SaveAllProfiles(options)
	options = options or {}

	local result = true
	local profilesToSave = {}

	for userId, profile in pairs(profiles) do
		table.insert(profilesToSave, {
			UserId = userId,
			Profile = profile,
		})
	end

	for _, profileEntry in ipairs(profilesToSave) do
		local userId = profileEntry.UserId
		local profile = profileEntry.Profile
		local player = Players:GetPlayerByUserId(userId)
		local playerName = if player then player.Name else string.format("UserId_%d", userId)

		if not saveProfileData(userId, playerName, profile, player, options) then
			result = false
		end
	end

	return result
end

function PlayerDataService.RemoveProfile(player)
	local userId = player.UserId

	if profiles[userId] then
		PlayerDataService.SaveProfile(player, { Force = true, Wait = true })
		profiles[userId] = nil
		print(string.format("[PlayerDataService] Removed profile for %s from memory.", player.Name))
	else
		print(string.format("[PlayerDataService] No profile to remove for %s.", player.Name))
	end
end

return PlayerDataService
