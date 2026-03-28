local ServerStorage = game:GetService("ServerStorage")

local Bootstrapper = require("@Core/Utility/Shared/Bootstrapper")
local Log = require("@Core/Utility/Shared/Log")

local StartTime = os.clock()
Log.Warn("Starting Server")

Bootstrapper.load(ServerStorage.Features, {
	Recursive = true,
	Suffix = "Service",
	UseExplicitFlag = false,
})
	:catch(Log.Warn)
	:await()

local EndTime = os.clock() - StartTime
Log.Warn(("Loading complete, took %.2f seconds"):format(EndTime))
