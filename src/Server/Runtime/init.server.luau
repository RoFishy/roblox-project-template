-- // Services
local ServerStorage = game:GetService("ServerStorage")
local Services = ServerStorage.Services

-- // Modules
local Bootstrapper = require("@Shared/Bootstrapper")
local Log = require("@Utility/Log")

-- // Init
local StartTime = os.clock()
Log.Warn("Starting Server")
Bootstrapper.load(Services)
local EndTime = os.clock() - StartTime
Log.Warn(("Loading complete, took %.2f seconds"):format(EndTime))
