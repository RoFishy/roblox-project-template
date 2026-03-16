local Types = require("@Core/Utility/Shared/Types")

return {
	SetupLeaderstats = function(Player: Player, Data: Types.UserData)
		local Leaderstats = Instance.new("Folder")
		Leaderstats.Name = "leaderstats"
		Leaderstats.Parent = Player

		local Currency = Instance.new("IntValue")
		Currency.Name = "Cash"
		Currency.Value = Data.Cash
		Currency.Parent = Leaderstats
	end,
}
