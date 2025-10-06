--[[
	Helper module for creating and managing datastores.
]]

-- @classmod DataStoreHelper
-- @author FaKeXSwing
-- @date 2025-10-02

----------------------------------
--        DEPENDENCIES
----------------------------------

local DataStoreHelper = {}
DataStoreHelper.__index = DataStoreHelper

----------------------------------
--    SERVICES & PRIMARY OBJECTS
----------------------------------

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

----------------------------------
--        CONFIG VARIABLES
----------------------------------

local MAX_TRIES = 5
local DEFAULT_SETTINGS = {
	["AutoSaveEnabled"] = false,
	["AutoSaveInterval"] = 180,
	["VerboseLogging"] = true,
	["DebugLogging"] = false,
	["StudioEnabled"] = false,
}

----------------------------------
--        PRIVATE FUNCTIONS
----------------------------------

function DataStoreHelper:__callWithRetry(Callback)
	local success, result
	for i = 1, MAX_TRIES do
		success, result = pcall(Callback)
		if success then
			return true, result
		end

		if i < MAX_TRIES then
			local yieldTime = math.pow(2, i) + math.random()
			task.wait(yieldTime)
		end
	end
	
	return false, result
end

function DataStoreHelper:__dbprint(...)
	if self.Settings.DebugLogging then
		print("[DEBUG]", ...)
	end
end

function DataStoreHelper:__dbwarn(...)
	if self.Settings.DebugLogging then
		warn("[DEBUG]", ...)
	end
end

function DataStoreHelper:__vprint(...)	
	if self.Settings.VerboseLogging then
		print(`[{self.Name}]`, ...)
	end
end

function DataStoreHelper:__vwarn(...)
	if self.Settings.VerboseLogging then
		warn(`[{self.Name}]`, ...)
	end
end

----------------------------------
--        PUBLIC FUNCTIONS
----------------------------------

function DataStoreHelper.new(Name)
	local self = setmetatable({}, DataStoreHelper)

	self.Name = Name
	self._dataStore = DataStoreService:GetDataStore(Name)
	self._dataCache = {}

	self.Settings = table.clone(DEFAULT_SETTINGS)

	self._autoSaveThread = nil
	self._settingCallbacks = {}

	local function createThread()
		if self._autoSaveThread then
			task.cancel(self._autoSaveThread)
			self._autoSaveThread = nil
		end

		self._autoSaveThread = task.spawn(function()
			while task.wait(self.Settings.AutoSaveInterval or 180) do
				self:Save()
			end
		end)
	end

	self:BindSetting("AutoSaveEnabled", function(Value)
		if not Value and self._autoSaveThread then
			task.cancel(self._autoSaveThread)
			self._autoSaveThread = nil
		else
			createThread()			
		end
	end)

	self:BindSetting("AutoSaveInterval", createThread)

	return self
end

--[[
	A function used to modify the Settings
	of the DataStoreHelper instance.
]]
------------------------------------------------------------------------------
--- @function DataStoreHelper:SetSetting
--- @param Index number | string A variable defining the setting to modify
--- @param Value any A variable defining the value to give the modified setting.
function DataStoreHelper:SetSetting(Index, Value)
	if self.Settings[Index] == nil then
		self:__vwarn(`{Index} is not a valid setting!`)
		return
	end

	self.Settings[Index] = Value
	self:__dbprint(`Successfully set '{Index}' to {(typeof(Value) == "boolean" and (Value and "enabled") or (not Value and "disabled")) or Value}`)

	for _, Callback in ipairs(self._settingCallbacks[Index] or {}) do
		if Callback and typeof(Callback) == "function" then
			task.spawn(Callback, Value)
		end
	end
end

--[[
	A function used to fetch the current
	Settings of the DataStoreHelper instance.
]]
------------------------------------------------------------------------------
--- @function DataStoreHelper:GetSettings
--- @return table Returns a dictionary with the current active settings.
function DataStoreHelper:GetSettings()
	return self.Settings or {}
end

--[[
	A function used to bind a callback to
	a value change on a specific setting.
]]
------------------------------------------------------------------------------
--- @function DataStoreHelper:BindSetting
--- @param Setting number | string A variable defining the setting to bind.
--- @param Callback function A variable defining the callback to be binded.
function DataStoreHelper:BindSetting(Setting, Callback)
	if self.Settings[Setting] == nil then
		self:__vwarn(`Cannot bind callback, setting {Setting} does not exist!`)
		return
	end

	self._settingCallbacks[Setting] = self._settingCallbacks[Setting] or {} -- Create a new table if it doesn't exist
	return table.insert(self._settingCallbacks[Setting], Callback)
end

--[[
	A function used to set a value to
	a key on the DataStoreHelper instance.
]]
------------------------------------------------------------------------------
--- @function DataStoreHelper:Set
--- @param Key number | string A variable defining the key to modify in the DataStore.
--- @param Value any A variable defining the value being assigned to the key.
function DataStoreHelper:Set(Key, Value)
	self._dataCache[Key] = Value
	self:__dbprint(`Successfully set the value of key: {Key}`)
end

--[[
	A function used to retrieve a value from
	a key on the DataStoreHelper instance.
]]
------------------------------------------------------------------------------
--- @function DataStoreHelper:Get
--- @param Key number | string A variable defining the key to access in the DataStore.
--- @return any Returns the value of the key in the DataStore.
function DataStoreHelper:Get(Key)
	return self._dataCache[Key] or self:Load(Key)
end

--[[
	A function used to save a specific key or
	all keys in the cache to the DataStore.
]]
------------------------------------------------------------------------------
--- @function DataStoreHelper:Save
--- @param Key number? | string? A optional variable defining the key to save in the DataStore.
function DataStoreHelper:Save(Key: string? | number?)
	if RunService:IsStudio() and not self.Settings.StudioEnabled then
		self:__vwarn("Saving is disabled in Studio!\n You can re-enable this through the settings of the DataStore.")
		return
	end

	local DataStore: DataStore = self._dataStore
	local function SaveData(TargetKey, Value)
		local success, result = self:__callWithRetry(function() 
			return DataStore:SetAsync(TargetKey, Value)	
		end)

		if success then
			self._dataCache[TargetKey] = nil
			self:__vwarn(`Successfully saved DataStore with key: {TargetKey}`)
		else
			self:__vwarn(`Failed to save DataStore with key ({TargetKey}) after {MAX_TRIES} tries.\n Error: {result}`)
		end
	end

	if Key and self._dataCache[Key] then -- Save only the specified key
		SaveData(Key, self._dataCache[Key])
	elseif not Key then -- Save everything in the cache if no key is specified
		for TargetKey, Value in pairs(self._dataCache) do
			SaveData(TargetKey, Value)
		end
	end
end

--[[
	A function used to load a specific key from
	the DataStore in the DataStoreHelper instance.
]]
------------------------------------------------------------------------------
--- @function DataStoreHelper:Load
--- @param Key number | string A variable defining the key to access in the DataStore.
--- @return any? Returns the value of the key in retrieved from the DataStore.
function DataStoreHelper:Load(Key)
	local DataStore: DataStore = self._dataStore
	local Success, Value = self:__callWithRetry(function()
		return DataStore:GetAsync(Key)
	end)

	if Success then
		self._dataCache[Key] = Value
		return Value
	else
		self:__vwarn(`Failed to fetch key {Key} from DataStore after {MAX_TRIES} tries.\n Error: {Value}`)
	end
end

return DataStoreHelper