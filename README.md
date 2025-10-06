# DataStoreHelper
A helper module used for managing custom DataStores in your Roblox game.

**Guide:**
```lua
local DataStoreHelper = require(pathToModule)
local DataStoreInstance = DataStoreHelper.new(dataStoreName)

DataStoreInstance:GetSettings() --> {
    ["AutoSaveEnabled"] = false,
	["AutoSaveInterval"] = 180,
	["VerboseLogging"] = true,
	["DebugLogging"] = false,
	["StudioEnabled"] = false,
} -- Default settings, modifiable thru :SetSetting()

DataStoreInstance:SetSetting(settingName, value)

DataStoreInstance:BindSetting(settingName, function()
    -- Logic for value change
end)

-- Key loading and retrieval
DataStoreInstance:Load(Key)
local Value = DataStoreInstance:Get(Key)

-- Key modification and saving
DataStoreInstance:Set(Key, Value)
DataStoreInstance:Save(Key, Value)

-- Save all keys in the DataStore
DataStoreInstance:Save()
```
