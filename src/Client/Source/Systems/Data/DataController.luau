local Sift = require("@Packages/Sift")

local DataController = {
	Network = require("@Core/Network/Systems/Data"),
	PlayerData = {},
}

function DataController.Start(self: DataController)
	self.Network.SyncData:connect(function(newData, _oldData)
		if Sift.Dictionary.equalsDeep(self.PlayerData, newData) then
			return
		end
		self.PlayerData = newData
	end)
end

export type DataController = typeof(DataController)

return DataController
