# DataStoreHelper
A helper module used for managing custom DataStores in your Roblox game.

## Getting Started
```lua
local DataStoreHelper = require(pathToModule)
local DataStoreInstance = DataStoreHelper.new(dataStoreName)

 -- Default DataStore settings
DataStoreInstance:GetSettings() == {
    ["AutoSaveEnabled"] = false, -- Determines if autosaves are enabled or not.
	["AutoSaveInterval"] = 180, -- Determines the interval between each autosave.
	["VerboseLogging"] = true, -- Determines if module should log basic information in the console.
	["DebugLogging"] = false, -- Determines if module should log debug information in the console.
	["StudioEnabled"] = false, -- Determines if DataStoreInstance:Save() works in Studio or not.
}

DataStoreInstance:SetSetting(settingName, value) -- Modifies a specific setting; Setting must be valid, and all values are accepted.

DataStoreInstance:BindSetting(settingName, function()
    -- Logic for value change
end)

-- Key loading and retrieval
DataStoreInstance:Load(Key) -- Loads provided key from DataStore
DataStoreInstance:Get(Key) -- Fetches key from Cache if available, failsaves to DataStoreInstance:Load()

-- Key modification and saving
DataStoreInstance:Set(Key, Value) -- Sets a value in the cache
DataStoreInstance:Save(Key) -- Saves down specific key in DataStore from cache

DataStoreInstance:Save() -- Save all keys in the DataStore
```
