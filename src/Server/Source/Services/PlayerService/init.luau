-- // Services
local Players = game:GetService("Players")

-- // Packages
local Lyra = require("@Packages/Lyra")

-- // util
local Schemas = require("@Shared/Schemas")
local Types = require("@Shared/Types")

local DataTemplate = require("@Services/PlayerService/DataTemplate")

-- // mod
local Network = require("@Shared/Network")

-- // l funcs
local function UpdateLeaderstats(UserId: string, newData: Types.UserData, _: Types.UserData?)
	local Player = Players:GetPlayerByUserId(tonumber(UserId))
	if Player then
		local leaderstats = Player:WaitForChild("leaderstats", 5) :: Folder
		local Cash = leaderstats:WaitForChild("Cash", 5) :: IntValue

		Cash.Value = newData.Cash
	end
end

local function SyncData(Key: string, NewData: Types.UserData, OldData: Types.UserData?)
	local Player = Players:GetPlayerByUserId(tonumber(Key))
	if Player then
		local _OldData = OldData or DataTemplate
		Network.Data.SyncData:fire(Player, NewData, _OldData)
	end
end

-- // Data store
local PlayerStore = Lyra.createPlayerStore({
	name = "PlayerData",
	template = DataTemplate,
	schema = Schemas.UserData,
	changedCallbacks = {
		UpdateLeaderstats,
		SyncData,
	},
})

local PlayerService = {
	Store = PlayerStore,
}

function PlayerService.Start(self: PlayerService)
	Players.PlayerAdded:Connect(function(Player: Player)
		self.Store:loadAsync(Player)
	end)
	Players.PlayerRemoving:Connect(function(Player: Player)
		self.Store:unloadAsync(Player)
	end)

	game:BindToClose(function()
		self.Store:closeAsync()
	end)
end

type PlayerService = typeof(PlayerService) & {
	Store: typeof(Lyra.createPlayerStore),
}

return PlayerService :: PlayerService
