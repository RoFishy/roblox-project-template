local Types = require("@Core/Utility/Shared/Types")

local DataUtil = {
	PlayerData = {} :: Types.UserData,
	ServerData = {},
}

function DataUtil.SetPlayerData(self: DataUtil, Data: Types.UserData)
	self.PlayerData = table.freeze(Data)
end

type DataUtil = typeof(DataUtil)

return DataUtil
