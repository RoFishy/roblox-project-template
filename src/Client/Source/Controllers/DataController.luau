-- // Util
-- // util
local Network = require("@Shared/Network")
local Types = require("@Shared/Types")

local Signals = require("@ClientUtility/Signals")

-- // init
local DataCache = {
	ServerData = {},
	PlayerData = {} :: Types.UserData,
	TempData = {},
}

-- // init
local DataController = {}

function DataController:Start()
	Network.Data.SyncData:connect(function(NewData, OldData)
		if NewData == nil or NewData == DataCache.PlayerData then
			return
		end
		DataCache.PlayerData = NewData
		Signals.PlayerDataChanged:Fire(NewData, OldData)
	end)
end

return DataController
