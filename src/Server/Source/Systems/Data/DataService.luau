local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Lyra = require("@Packages/Lyra")

local Schemas = require("@Core/Utility/Shared/Schemas")
local Types = require("@Core/Utility/Shared/Types")

local DataTemplate = require("@Core/Configuration/Data")
local Network = require("@Core/Network/Systems/Data")
local Signals = require("@Server/Utility/Signals")

local Leaderstats = require("./Leaderstats")

local function SyncData(Key: string, NewData: Types.UserData, OldData: Types.UserData?)
	local Player = Players:GetPlayerByUserId(tonumber(Key))
	if Player then
		local _OldData = OldData or DataTemplate
		Network.SyncData:fire(Player, NewData, _OldData)
	end
end

local PlayerStore = Lyra.createPlayerStore({
	name = RunService:IsStudio() and "TestingData_1" or "PlayerData",
	template = DataTemplate,
	schema = Schemas.UserData,
	changedCallbacks = {
		SyncData,
		Leaderstats.Update,
	},
})

local DataService = {
	Store = PlayerStore,
	Network = Network,
}

function DataService.Start(self: DataService)
	Players.PlayerAdded:Connect(function(Player)
		self.Store:load(Player):andThen(function()
			Signals.PlayerRegistered:Fire(Player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		Signals.PlayerUnregistered:Fire(Player)

		task.defer(function()
			self.Store:unload(Player)
		end)
	end)

	game:BindToClose(function()
		self.Store:close()
	end)
end

export type DataService = typeof(DataService)

return DataService
