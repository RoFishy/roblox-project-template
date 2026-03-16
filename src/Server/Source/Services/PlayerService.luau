local Players = game:GetService("Players")

local DataUtil = require("@Server/Utility/DataUtil")

local PlayerService = {
	Utility = require("@Core/Utility/Systems/PlayerUtility"),
	Network = require("@Core/Network/Systems/PlayerNetwork"),
}

function PlayerService.Start(self: PlayerService)
	Players.PlayerAdded:Connect(function(Player: Player)
		DataUtil.Store:load(Player):andThen(function()
			local Data = DataUtil.Store:getAsync(Player)
			if Data then
				self.Utility.SetupLeaderstats(Player, Data)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(Player: Player)
		DataUtil.Store:unloadAsync(Player)
	end)

	game:BindToClose(function(): ...any
		DataUtil.Store:closeAsync()
	end)
end

type PlayerService = typeof(PlayerService)

return PlayerService :: PlayerService
