-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = ReplicatedStorage:WaitForChild("Client"):WaitForChild("Controllers") :: Folder

-- // Modules
local Bootstrapper = require("@Shared/Bootstrapper")
local Log = require("@Shared/Utility/Log")

local StartTime = os.clock()
Log.Warn("Starting client")
Bootstrapper.load(Controllers):catch(Log.Warn)
local EndTime = os.clock() - StartTime
Log.Warn(("Loading complete, took %.2f seconds"):format(EndTime))
