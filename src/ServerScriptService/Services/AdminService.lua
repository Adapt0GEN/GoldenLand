-- AdminService
-- Dev-only chat commands for quickly setting test resources and progression.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerDataService = require(script.Parent.PlayerDataService)
local CurrencyService = require(script.Parent.CurrencyService)
local PlotService = require(script.Parent.PlotService)

local AdminService = {}

-- Add explicit developer Roblox UserIds here, for example:
-- [123456789] = true,
local ADMIN_USER_IDS = {}

local RESOURCE_ADDERS = {
	Gold = CurrencyService.AddGold,
	Wood = CurrencyService.AddWood,
	Stone = CurrencyService.AddStone,
	Metal = CurrencyService.AddMetal,
	MetalIngot = CurrencyService.AddMetalIngot,
	MetalParts = CurrencyService.AddMetalParts,
}

local RESOURCE_NAMES = {
	Gold = true,
	Wood = true,
	Stone = true,
	Metal = true,
	MetalIngot = true,
	MetalParts = true,
}

local RESOURCE_ALIASES = {
	gold = "Gold",
	wood = "Wood",
	stone = "Stone",
	metal = "Metal",
	metalingot = "MetalIngot",
	metalparts = "MetalParts",
}

local RESOURCE_SET_ALL_NAMES = {
	"Gold",
	"Wood",
	"Stone",
	"Metal",
	"MetalIngot",
	"MetalParts",
}

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

local function sendPlayerMessage(player, message)
	getRemoteEvent("PlayerMessageEvent"):FireClient(player, message)
end

local function isAdmin(player)
	if not RunService:IsStudio() then
		return false
	end

	if ADMIN_USER_IDS[player.UserId] == true then
		return true
	end

	return game.CreatorType == Enum.CreatorType.User
		and game.CreatorId == player.UserId
end

local function parseNonNegativeInteger(valueText)
	local value = tonumber(valueText)

	if not value or value < 0 or value % 1 ~= 0 then
		return nil
	end

	return value
end

local function normalizeResourceName(resourceText)
	if not resourceText then
		return nil
	end

	if RESOURCE_NAMES[resourceText] then
		return resourceText
	end

	return RESOURCE_ALIASES[string.lower(resourceText)]
end

local function updateAndSaveProfile(player)
	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end
end

local function refreshPlotVisual(player, profile)
	if profile.PlotUnlocked == true then
		PlotService.CreateTestPlot(player)
	end
end

local function printStatus(player, profile)
	print(string.format(
		"[AdminService] %s status: Gold=%d Wood=%d Stone=%d Metal=%d MetalIngot=%d MetalParts=%d HouseLevel=%d StorageLevel=%d ToolKitLevel=%d ForgeLevel=%d ForestUnlocked=%s RockZoneUnlocked=%s",
		player.Name,
		profile.Gold or 0,
		profile.Wood or 0,
		profile.Stone or 0,
		profile.Metal or 0,
		profile.MetalIngot or 0,
		profile.MetalParts or 0,
		profile.HouseLevel or 1,
		profile.StorageLevel or 0,
		profile.ToolKitLevel or 0,
		profile.ForgeLevel or 0,
		tostring(profile.ForestUnlocked == true),
		tostring(profile.RockZoneUnlocked == true)
	))
end

local function handleAddCommand(player, args)
	local resourceName = normalizeResourceName(args[3])
	local amount = parseNonNegativeInteger(args[4])

	if not resourceName or not amount then
		warn("[AdminService] Usage: /gl add Gold|Wood|Stone|Metal|MetalIngot|MetalParts amount")
		return
	end

	local addResource = RESOURCE_ADDERS[resourceName]

	if not addResource then
		warn(string.format("[AdminService] Unknown resource: %s", tostring(args[3])))
		return
	end

	addResource(player, amount)
	updateAndSaveProfile(player)
	sendPlayerMessage(player, string.format("Admin: %s +%d", resourceName, amount))
	print(string.format("[AdminService] Added %d %s to %s.", amount, resourceName, player.Name))
end

local function setResource(profile, resourceName, amount)
	profile[resourceName] = amount
end

local function handleSetCommand(player, profile, args)
	local resourceText = args[3]
	local amount = parseNonNegativeInteger(args[4])

	if not resourceText or not amount then
		warn("[AdminService] Usage: /gl set Gold|Wood|Stone|Metal|MetalIngot|MetalParts|all amount")
		return
	end

	if string.lower(resourceText) == "all" then
		for _, resourceName in ipairs(RESOURCE_SET_ALL_NAMES) do
			setResource(profile, resourceName, amount)
		end
	else
		local resourceName = normalizeResourceName(resourceText)

		if not resourceName then
			warn(string.format("[AdminService] Unknown resource: %s", tostring(resourceText)))
			return
		end

		setResource(profile, resourceName, amount)
	end

	PlayerDataService.MarkDirty(player)
	updateAndSaveProfile(player)
	sendPlayerMessage(player, string.format("Admin: resources set to %d", amount))
	print(string.format(
		"[AdminService] Set resources for %s. Gold=%d Wood=%d Stone=%d Metal=%d MetalIngot=%d MetalParts=%d.",
		player.Name,
		profile.Gold,
		profile.Wood,
		profile.Stone,
		profile.Metal,
		profile.MetalIngot or 0,
		profile.MetalParts or 0
	))
end

local function handleToolsCommand(player, profile, args)
	local level = parseNonNegativeInteger(args[3])

	if not level or level > 2 then
		warn("[AdminService] Usage: /gl tools 0|1|2")
		return
	end

	profile.ToolKitLevel = level
	PlayerDataService.MarkDirty(player)
	refreshPlotVisual(player, profile)
	updateAndSaveProfile(player)
	sendPlayerMessage(player, string.format("Admin: tools level %d", level))
	print(string.format("[AdminService] Set ToolKitLevel=%d for %s.", level, player.Name))
end

local function handleHouseCommand(player, profile, args)
	local level = parseNonNegativeInteger(args[3])

	if not level or level < 1 or level > 3 then
		warn("[AdminService] Usage: /gl house 1|2|3")
		return
	end

	profile.HouseLevel = level
	PlayerDataService.MarkDirty(player)
	refreshPlotVisual(player, profile)
	updateAndSaveProfile(player)
	sendPlayerMessage(player, string.format("Admin: house level %d", level))
	print(string.format("[AdminService] Set HouseLevel=%d for %s.", level, player.Name))
end

local function handleStorageCommand(player, profile, args)
	local level = parseNonNegativeInteger(args[3])

	if not level or level > 2 then
		warn("[AdminService] Usage: /gl storage 0|1|2")
		return
	end

	profile.StorageLevel = level
	profile.StorageBuilt = level >= 1
	PlayerDataService.MarkDirty(player)
	refreshPlotVisual(player, profile)
	updateAndSaveProfile(player)
	sendPlayerMessage(player, string.format("Admin: storage level %d", level))
	print(string.format(
		"[AdminService] Set StorageLevel=%d StorageBuilt=%s for %s.",
		level,
		tostring(profile.StorageBuilt == true),
		player.Name
	))
end

local function handleForgeCommand(player, profile, args)
	local level = parseNonNegativeInteger(args[3])

	if not level or level > 1 then
		warn("[AdminService] Usage: /gl forge 0|1")
		return
	end

	profile.ForgeLevel = level
	PlayerDataService.MarkDirty(player)
	refreshPlotVisual(player, profile)
	updateAndSaveProfile(player)
	sendPlayerMessage(player, string.format("Admin: forge level %d", level))
	print(string.format("[AdminService] Set ForgeLevel=%d for %s.", level, player.Name))
end

local function splitCommand(message)
	local args = {}

	for token in string.gmatch(message, "%S+") do
		table.insert(args, token)
	end

	return args
end

local function handleCommand(player, message)
	local args = splitCommand(message)

	if args[1] ~= "/gl" then
		return
	end

	if not isAdmin(player) then
		warn(string.format("[AdminService] Unauthorized admin command attempt by %s", player.Name))
		return
	end

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[AdminService] Profile for %s was not found.", player.Name))
		return
	end

	local command = string.lower(args[2] or "")

	if command == "status" then
		printStatus(player, profile)
	elseif command == "add" then
		handleAddCommand(player, args)
	elseif command == "set" then
		handleSetCommand(player, profile, args)
	elseif command == "tools" then
		handleToolsCommand(player, profile, args)
	elseif command == "house" then
		handleHouseCommand(player, profile, args)
	elseif command == "storage" then
		handleStorageCommand(player, profile, args)
	elseif command == "forge" then
		handleForgeCommand(player, profile, args)
	else
		warn("[AdminService] Unknown command. Use /gl status, add, set, tools, house, storage, or forge.")
	end
end

function AdminService.Start()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			handleCommand(player, message)
		end)
	end)

	for _, player in Players:GetPlayers() do
		player.Chatted:Connect(function(message)
			handleCommand(player, message)
		end)
	end

	print("[AdminService] Dev admin commands initialized.")
end

return AdminService
