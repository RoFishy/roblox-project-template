-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = ReplicatedStorage:WaitForChild("Client"):WaitForChild("Controllers")

-- // Modules
local Bootstrapper = require("@Shared/Bootstrapper")
local Log = require("@Utility/Log")

local StartTime = os.clock()
Log.Warn("Starting client")
Bootstrapper.load(Controllers)
local EndTime = os.clock() - StartTime
Log.Warn(("Loading complete, took %.2f seconds"):format(EndTime))
