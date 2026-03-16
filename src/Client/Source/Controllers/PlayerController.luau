local Sift = require("@Packages/Sift")

local DataUtil = require("@Client/Utility/DataUtil")
local Signals = require("@Client/Utility/Signals")

local PlayerController = {
	Utility = require("@Core/Utility/Systems/PlayerUtility"),
	Network = require("@Core/Network/Systems/PlayerNetwork"),
}

function PlayerController.Start(self: PlayerController)
	self.Network.SyncData:connect(function(NewData, OldData)
		if NewData == nil or Sift.Dictionary.equalsDeep(NewData, OldData) then
			return
		end

		DataUtil:SetPlayerData(NewData)
		Signals.PlayerDataChanged:Fire(NewData, OldData)
	end)
end

type PlayerController = typeof(PlayerController)

return PlayerController
