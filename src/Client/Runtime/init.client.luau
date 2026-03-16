-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = ReplicatedStorage:WaitForChild("Client"):WaitForChild("Controllers")

-- // Modules
local Bootstrapper = require("@Core/Utility/Shared/Bootstrapper")
local Log = require("@Core/Utility/Shared/Log")

local StartTime = os.clock()
Log.Warn("Starting client")
Bootstrapper.load(Controllers):catch(Log.Warn):await()
local EndTime = os.clock() - StartTime
Log.Warn(("Loading complete, took %.2f seconds"):format(EndTime))
