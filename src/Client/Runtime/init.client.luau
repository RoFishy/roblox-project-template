local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrapper = require("@Core/Utility/Shared/Bootstrapper")
local Log = require("@Core/Utility/Shared/Log")

local StartTime = os.clock()
Log.Warn("Starting Client")

Bootstrapper.load(ReplicatedStorage.Client.Features, {
	Recursive = true,
	Suffix = "Controller",
	UseExplicitFlag = false,
})
	:catch(Log.Warn)
	:await()

local EndTime = os.clock() - StartTime
Log.Warn(("Loading complete, took %.2f seconds"):format(EndTime))
