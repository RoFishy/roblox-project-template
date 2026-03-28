-- // Services
local RunService = game:GetService("RunService")

-- // Types
type LogLevel = "Debugging" | "Information" | "Warning"

export type BootstrapOptions = {
	Recursive: boolean?,
	Suffix: string?,
	UseExplicitFlag: boolean?,
}

type BootstrapModuleObject = {
	Dependencies: { string }?,
	IsBootstrapModule: boolean?,
	Init: ((self: any, deps: { [string]: any }) -> ())?,
	Start: ((self: any) -> ())?,
	[string]: any,
}

type BootstrapModuleRecord = {
	Name: string,
	Script: ModuleScript,
	Object: BootstrapModuleObject,
	Dependencies: { string },
}

type BootstrapStore = {
	Discovered: { [string]: BootstrapModuleRecord },
	Initialized: { [string]: BootstrapModuleRecord },
	Started: { [string]: BootstrapModuleRecord },
	Failed: { [string]: BootstrapModuleRecord },
	Order: { BootstrapModuleRecord },
}

-- // Utils
local Log = require("@Core/Utility/Shared/Log")

-- // Packages
local Promise = require("@Packages/TypedPromise")

-- // Init
local Bootstrapper = {
	_Services = {
		Discovered = {},
		Initialized = {},
		Started = {},
		Failed = {},
		Order = {},
	} :: BootstrapStore,

	_Controllers = {
		Discovered = {},
		Initialized = {},
		Started = {},
		Failed = {},
		Order = {},
	} :: BootstrapStore,

	_Verbose = true,
	_VerboseLevel = 2, -- 1 silences warnings, 2 doesn't.
}

local isServer = RunService:IsServer()
local typePlural = isServer and "Services" or "Controllers"
local typeSingle = isServer and "Service" or "Controller"
local typePluralLower = string.lower(typePlural)
local typeSingleLower = string.lower(typeSingle)

local defaultSuffix = isServer and "Service" or "Controller"
local store: BootstrapStore = isServer and Bootstrapper._Services or Bootstrapper._Controllers

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

local function clearStore(targetStore: BootstrapStore)
	table.clear(targetStore.Discovered)
	table.clear(targetStore.Initialized)
	table.clear(targetStore.Started)
	table.clear(targetStore.Failed)
	table.clear(targetStore.Order)
end

local function normalizeDependencies(value: any): { string }
	if type(value) ~= "table" then
		return {}
	end

	local result = {}

	for _, dependency in ipairs(value) do
		if type(dependency) == "string" then
			table.insert(result, dependency)
		end
	end

	return result
end

local function endsWith(value: string, suffix: string): boolean
	return suffix == "" or string.sub(value, -#suffix) == suffix
end

local function shouldBootstrapModule(
	moduleScript: ModuleScript,
	options: BootstrapOptions,
	requiredModuleOrNil: BootstrapModuleObject?
): boolean
	local useExplicitFlag = options.UseExplicitFlag == true
	local suffix = options.Suffix or defaultSuffix

	if useExplicitFlag then
		if requiredModuleOrNil and requiredModuleOrNil.IsBootstrapModule ~= nil then
			return requiredModuleOrNil.IsBootstrapModule == true
		end

		return false
	end

	if requiredModuleOrNil and requiredModuleOrNil.IsBootstrapModule == false then
		return false
	end

	return endsWith(moduleScript.Name, suffix)
end

local function discoverFromFolder(
	folder: Instance,
	options: BootstrapOptions,
	records: { [string]: BootstrapModuleRecord }
)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Folder") then
			if options.Recursive ~= false then
				discoverFromFolder(child, options, records)
			end

			continue
		end

		if not child:IsA("ModuleScript") then
			continue
		end

		local moduleScript = child :: ModuleScript

		local success, requiredModule = pcall(require, moduleScript)
		if not success then
			error(`Failed to require module "{moduleScript:GetFullName()}": {tostring(requiredModule)}`)
		end

		if type(requiredModule) ~= "table" then
			log("Debugging", `Skipping "{moduleScript:GetFullName()}" because it does not return a table.`)
			continue
		end

		local moduleObject = requiredModule :: BootstrapModuleObject

		if not shouldBootstrapModule(moduleScript, options, moduleObject) then
			log("Debugging", `Skipping non-bootstrap module "{moduleScript:GetFullName()}".`)
			continue
		end

		if records[moduleScript.Name] then
			error(
				`Duplicate {typeSingleLower} name "{moduleScript.Name}" found while bootstrapping. `
					.. `Use unique module names for bootstrap modules.`
			)
		end

		local record: BootstrapModuleRecord = {
			Name = moduleScript.Name,
			Script = moduleScript,
			Object = moduleObject,
			Dependencies = normalizeDependencies(moduleObject.Dependencies),
		}

		log("Information", `Discovered {typeSingleLower} "{record.Name}"`)
		records[record.Name] = record
	end
end

local function validateDependencies()
	for moduleName, record in pairs(store.Discovered) do
		for _, dependencyName in ipairs(record.Dependencies) do
			if not store.Discovered[dependencyName] then
				error(
					`{typeSingle} "{moduleName}" depends on missing bootstrapped {typeSingleLower} "{dependencyName}".`
				)
			end
		end
	end
end

local function buildDependencyOrder(): { BootstrapModuleRecord }
	local ordered = {}
	local visited: { [string]: boolean } = {}
	local visiting: { [string]: boolean } = {}

	local function visit(moduleName: string)
		if visited[moduleName] then
			return
		end

		if visiting[moduleName] then
			error(`Circular dependency detected while resolving "{moduleName}".`)
		end

		local record = store.Discovered[moduleName]
		if not record then
			error(`Attempted to resolve unknown {typeSingleLower} "{moduleName}".`)
		end

		visiting[moduleName] = true

		for _, dependencyName in ipairs(record.Dependencies) do
			visit(dependencyName)
		end

		visiting[moduleName] = nil
		visited[moduleName] = true

		table.insert(ordered, record)
	end

	for moduleName in pairs(store.Discovered) do
		visit(moduleName)
	end

	return ordered
end

local function buildDependencyTable(record: BootstrapModuleRecord): { [string]: any }
	local deps = {}

	for _, dependencyName in ipairs(record.Dependencies) do
		local dependencyRecord = store.Discovered[dependencyName]
		if not dependencyRecord then
			error(`Failed to resolve dependency "{dependencyName}" for {typeSingleLower} "{record.Name}".`)
		end

		deps[dependencyName] = dependencyRecord.Object
	end

	return deps
end

local function initializeModules(orderedModules: { BootstrapModuleRecord })
	return Promise.new(function(resolve, reject)
		for _, record in ipairs(orderedModules) do
			local moduleObject = record.Object

			if moduleObject.Init then
				log("Information", `Initializing {typeSingleLower} "{record.Name}"...`)

				local success, response = pcall(function()
					moduleObject.Init(moduleObject, buildDependencyTable(record))
				end)

				if not success then
					store.Failed[record.Name] = record

					local message = `Failed to initialize {typeSingleLower} "{record.Name}": {tostring(response)}`
					log("Warning", message)
					reject(message)
					return
				end

				log("Information", `Initialized {typeSingleLower} "{record.Name}"`)
			else
				log("Debugging", `{typeSingle} "{record.Name}" has no Init; skipping.`)
			end

			store.Initialized[record.Name] = record
		end

		resolve()
	end)
end

local function startModules(orderedModules: { BootstrapModuleRecord })
	return Promise.new(function(resolve, reject)
		for _, record in ipairs(orderedModules) do
			local moduleObject = record.Object

			if moduleObject.Start then
				log("Information", `Starting {typeSingleLower} "{record.Name}"...`)

				local success, response = pcall(function()
					moduleObject.Start(moduleObject)
				end)

				if not success then
					store.Failed[record.Name] = record

					local message = `Failed to start {typeSingleLower} "{record.Name}": {tostring(response)}`
					log("Warning", message)
					reject(message)
					return
				end

				log("Information", `Started {typeSingleLower} "{record.Name}"`)
			else
				log("Debugging", `{typeSingle} "{record.Name}" has no Start; skipping.`)
			end

			store.Started[record.Name] = record
		end

		resolve()
	end)
end

function Bootstrapper.get(name: string): any
	local record = store.Discovered[name]
	return if record then record.Object else nil
end

function Bootstrapper.load(root: Instance, options: BootstrapOptions?)
	assert(root, "A root folder/instance must be provided.")

	local resolvedOptions: BootstrapOptions = options
		or {
			Recursive = true,
			Suffix = defaultSuffix,
			UseExplicitFlag = false,
		}

	return Promise.new(function(resolve, reject)
		clearStore(store)

		log("Information", `Loading {typePluralLower} from "{root:GetFullName()}"...`)

		local success, response = pcall(function()
			discoverFromFolder(root, resolvedOptions, store.Discovered)

			if next(store.Discovered) == nil then
				log("Warning", `No {typePluralLower} found in "{root:GetFullName()}".`)
			end

			validateDependencies()

			local orderedModules = buildDependencyOrder()
			store.Order = orderedModules

			initializeModules(orderedModules)
				:andThen(function()
					log("Information", `Initialized {typePluralLower}. Starting...`)
					return startModules(orderedModules)
				end)
				:andThen(function()
					log("Information", `Started {typePluralLower}.`)
					resolve()
				end)
				:catch(reject)
		end)

		if not success then
			log("Warning", tostring(response))
			reject(response)
		end
	end)
end

return Bootstrapper
