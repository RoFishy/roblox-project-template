local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Lyra = require("@Packages/Lyra")

local Schemas = require("@Core/Utility/Shared/Schemas")
local Types = require("@Core/Utility/Shared/Types")

local DataTemplate = require("@Core/Configuration/Data")

local Network = require("@Core/Network/Systems/PlayerNetwork")

local function SyncData(Key: string, NewData: Types.UserData, OldData: Types.UserData?)
	local Player = Players:GetPlayerByUserId(tonumber(Key))
	if Player then
		local _OldData = OldData or DataTemplate
		Network.SyncData:fire(Player, NewData, _OldData)
	end
end

local function UpdateLeaderstats(Key: string, NewData: Types.UserData, _: Types.UserData?)
	local Player = Players:GetPlayerByUserId(tonumber(Key))
	if Player then
		local Leaderstats = Player:FindFirstChild("leaderstats")
		if not Leaderstats then
			return
		end

		local Currency = Leaderstats:FindFirstChild("Cash") :: IntValue
		if not Currency then
			return
		end

		Currency.Value = NewData.Cash
	end
end

local PlayerStore = Lyra.createPlayerStore({
	name = RunService:IsStudio() and "TestingData_1" or "PlayerData",
	template = DataTemplate,
	schema = Schemas.UserData,
	changedCallbacks = {
		SyncData,
		UpdateLeaderstats,
	},
})

local DataUtil = {
	Store = PlayerStore,
}

return DataUtil :: typeof(DataUtil)
