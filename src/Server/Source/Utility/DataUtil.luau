local Players = game:GetService("Players")

local Lyra = require("@Packages/Lyra")

local Schemas = require("@Shared/Schemas")
local Types = require("@Shared/Types")

local DataTemplate = require("@Shared/Config/DataTemplate")

local Network = require("@Shared/Network")

local function SyncData(Key: string, NewData: Types.UserData, OldData: Types.UserData?)
	local Player = Players:GetPlayerByUserId(tonumber(Key))
	if Player then
		local _OldData = OldData or DataTemplate
		Network.Data.SyncData:fire(Player, NewData, _OldData)
	end
end

local PlayerStore = Lyra.createPlayerStore({
	name = "PlayerData",
	template = DataTemplate,
	schema = Schemas.UserData,
	changedCallbacks = {
		SyncData,
	},
})

local DataUtil = {
	Store = PlayerStore,
}

return DataUtil :: typeof(DataUtil)
