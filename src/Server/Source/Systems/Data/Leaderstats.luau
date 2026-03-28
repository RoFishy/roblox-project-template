local Players = game:GetService("Players")

local Types = require("@Core/Utility/Shared/Types")

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

local function SetupLeaderstats(Player: Player, Data: Types.UserData)
	local Leaderstats = Instance.new("Folder")
	Leaderstats.Name = "leaderstats"
	Leaderstats.Parent = Player

	local Currency = Instance.new("IntValue")
	Currency.Name = "Cash"
	Currency.Value = Data.Cash
	Currency.Parent = Leaderstats
end

return {
	Update = UpdateLeaderstats,
	Setup = SetupLeaderstats,
}
