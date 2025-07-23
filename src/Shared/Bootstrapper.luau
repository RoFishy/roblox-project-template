-- // Services
local RunService = game:GetService("RunService")

-- // Types
type LogLevel = "Debugging" | "Information" | "Warning"

-- // Utils
local Log = require("@Utility/Log")

-- // Packages
local Promise = require("@Packages/TypedPromise")

-- // Init
local Bootstrapper = {
	_Services = {
		Waiting = {},
		Initialized = {},
		Started = {},
		Failed = {},
	},
	_Controllers = {
		Waiting = {},
		Initialized = {},
		Started = {},
		Failed = {},
	},
	_Verbose = true,
	_VerboseLevel = 2, -- 1 silences warnings, 2 doesn't.
}

local isServer = RunService:IsServer()
local typePlural = isServer and "Services" or "Controllers"
local typeSingle = isServer and "Service" or "Controller"
local typePluralLower = string.lower(typePlural)
local typeSingleLower = string.lower(typeSingle)
local store = isServer and Bootstrapper._Services or Bootstrapper._Controllers

local function log(level: LogLevel, message: string)
	if not Bootstrapper._Verbose then
		return
	end

	if level == "Debugging" then
		Log.Debug(message)
	elseif level == "Information" then
		Log.Info(message)
	elseif level == "Warning" and Bootstrapper._VerboseLevel ~= 1 then
		Log.Warn(message)
	end
end

local function Start()
	return Promise.new(function(resolve, reject)
		local startPromises = {} :: any

		for _, Module in pairs(store.Initialized) do
			if Module:IsA("ModuleScript") then
				local requiredModule = require(Module) :: any

				log("Information", `Starting {typeSingleLower} "{Module.Name}"...`)

				if requiredModule and requiredModule.Start then
					table.insert(
						startPromises,
						Promise.new(function(innerResolve, innerReject)
							local success, response = pcall(function()
								return requiredModule:Start()
							end)

							if success then
								log("Information", `Started {typeSingleLower} "{Module.Name}"`)
								store.Started[Module.Name] = Module
								innerResolve()
							else
								log(
									"Warning",
									`Failed to start {typeSingleLower} "{Module.Name}" with response: {response}`
								)
								store.Failed[Module.Name] = Module
								innerReject(response)
							end
						end)
					)
				end
			end
		end

		store.Waiting = {}

		Promise.all(startPromises)
			:andThen(function()
				log("Information", `Started {typePluralLower}.`)
				resolve()
			end)
			:catch(reject)
	end)
end
local function Initialize()
	return Promise.new(function(resolve, reject)
		local initPromises = {} :: any

		for _, Module in pairs(store.Waiting) do
			if Module:IsA("ModuleScript") then
				local requiredModule = require(Module) :: any

				log("Information", `Initializing {typeSingleLower} "{Module.Name}"...`)

				if requiredModule and requiredModule.Init then
					table.insert(
						initPromises,
						Promise.new(function(innerResolve, innerReject)
							local success, response = pcall(function()
								requiredModule:Init()
							end)

							if success then
								log("Information", `Initialized {typeSingleLower} "{Module.Name}"`)
								store.Initialized[Module.Name] = Module
								innerResolve()
							else
								log(
									"Warning",
									`Failed to initialize {typeSingleLower} "{Module.Name}" with response: {response}`
								)
								store.Failed[Module.Name] = Module
								innerReject(response)
							end
						end)
					)
				else
					store.Initialized[Module.Name] = Module
				end
			end
		end

		store.Waiting = {}

		if #store.Initialized > 0 then
			log("Information", `Initialized {typePluralLower}. Starting...`)
		end

		Promise.all(initPromises)
			:andThen(function()
				return Start()
			end)
			:andThen(resolve)
			:catch(reject)
	end)
end
local function Load(Folder)
	return Promise.new(function(resolve, reject)
		log("Information", `Loading {typePlural}`)

		for _, child in pairs(Folder:GetChildren()) do
			if child:IsA("ModuleScript") then
				local moduleScript = child :: ModuleScript

				store.Waiting[moduleScript.Name] = moduleScript :: any
			end
		end

		log("Information", `Loaded {typePlural}. Initializing...`)

		Initialize():andThen(function()
			resolve()
		end):catch(function(err)
			reject(err)
		end)
	end)
end

function Bootstrapper.load(Folder: Folder)
	assert(Folder, "A folder must be provided.")
	assert(#Folder:GetChildren() > 0, "Folder is empty.")

	return Promise.new(function(resolve)
		Load(Folder):await()
		resolve()
	end)
end

return Bootstrapper
