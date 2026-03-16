-- // Services
local ServerStorage = game:GetService("ServerStorage")
local Services = ServerStorage.Services

-- // Modules
local Bootstrapper = require("@Core/Utility/Shared/Bootstrapper")
local Log = require("@Core/Utility/Shared/Log")

-- // Init
local StartTime = os.clock()
Log.Warn("Starting Server")
Bootstrapper.load(Services):catch(Log.Warn):await()
local EndTime = os.clock() - StartTime
Log.Warn(("Loading complete, took %.2f seconds"):format(EndTime))
