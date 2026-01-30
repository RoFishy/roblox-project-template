-- // Services
local Players = game:GetService("Players")

local DataUtil = require("@Server/Utility/DataUtil")

local PlayerService = {}

function PlayerService.Start(_: PlayerService)
	Players.PlayerAdded:Connect(function(Player: Player)
		DataUtil.Store:loadAsync(Player)
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
