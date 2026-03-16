local Remo = require("@Packages/Remo")
local Schemas = require("@Core/Utility/Shared/Schemas")
local Types = require("@Core/Utility/Shared/Types")

type Remotes = Remo.Remotes<{
	SyncData: Remo.ServerToClient<(Types.UserData, Types.UserData)>,
}>

local Remotes: Remotes = Remo.createRemotes({
	SyncData = Remo.remote(Schemas.UserData, Schemas.UserData),
})

return Remotes
