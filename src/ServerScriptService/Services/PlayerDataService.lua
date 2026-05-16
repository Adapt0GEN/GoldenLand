-- PlayerDataService
-- Stores simple in-memory player profiles for the current server session.

local PlayerDataService = {}

local profiles = {}

local function createDefaultProfile(player)
	return {
		UserId = player.UserId,
		Gold = 0,
		Wood = 0,
		Stone = 0,
		HouseLevel = 1,
		PlotUnlocked = false,
		CurrentQuestId = nil,
		CompletedQuests = {},
	}
end

function PlayerDataService.CreateProfile(player)
	local userId = player.UserId

	if profiles[userId] then
		print(string.format("[PlayerDataService] Profile for %s is already loaded.", player.Name))
		return profiles[userId]
	end

	local profile = createDefaultProfile(player)
	profiles[userId] = profile

	print(string.format("[PlayerDataService] Created starter profile for %s (UserId: %d).", player.Name, userId))

	return profile
end

function PlayerDataService.GetProfile(player)
	return profiles[player.UserId]
end

function PlayerDataService.RemoveProfile(player)
	local userId = player.UserId

	if profiles[userId] then
		profiles[userId] = nil
		print(string.format("[PlayerDataService] Removed profile for %s from memory.", player.Name))
	else
		print(string.format("[PlayerDataService] No profile to remove for %s.", player.Name))
	end
end

return PlayerDataService
