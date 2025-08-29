-- // Packages
local Remo = require("@Packages/Remo")

local Schemas = require("@Shared/Schemas")
local Types = require("@Shared/Types")

type Remotes = Remo.Remotes<{
	Data: {
		SyncData: Remo.ServerToClient<(Types.UserData, Types.UserData)>,
	},
}>

local Remotes: Remotes = Remo.createRemotes({
	Data = Remo.namespace({
		SyncData = Remo.remote(Schemas.UserData, Schemas.UserData),
	}),
})

return Remotes
