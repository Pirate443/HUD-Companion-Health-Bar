local config = require("Pirate.HUD Companion Health Bar.config")
--local cf = require("Pirate.HUD Companion Health.config").mcm
local log = mwse.Logger.new()
local presets = {}
-- Таблица для хранения загруженных пресетов.
local loadedPresets = {}

-- Имена базовых пресетов, которые нельзя перезаписывать.
local protectedPresets = {
    ["Mesafoo Classic"] = true,
    ["Pirate v1 Full"] = true,
    ["Pirate v1 Compact"] = true,
    ["Pirate v1 Small"] = true,
    ["Pirate v2 Full"] = true,
    ["Pirate v2 Compact"] = true,
    ["Spammer21 Compact"] = true,
}

function presets.isProtected(presetName)
    return protectedPresets[presetName] == true
end

-- Получить список всех файлов пресетов (имена без расширения).
function presets.getFileList()
    local files = {}
    local path = "Data Files\\MWSE\\config\\" .. config.presetPath .. "\\"
    
    if lfs.attributes(path, "mode") == "directory" then
        for file in lfs.dir(path) do
            if file:lower():endswith(".json") then
                local name = file:gsub("%.json$", "")
                table.insert(files, name)
            end
        end
    end
    
    table.sort(files)
    return files
end

-- Загрузить данные пресета по ID (имени файла).
function presets.loadPresetData(id)
    log:trace("loadPresetData called with id: " .. tostring(id))
    
    if loadedPresets[id] then
        log:trace("Returning cached preset: " .. id)
        return loadedPresets[id]
    end
    
    local data = mwse.loadConfig(config.presetPath .. "/" .. id)
    if data then
        data.id = id
        data.presetName = data.presetName or id
        loadedPresets[id] = data
        log:info("Preset loaded successfully: " .. id)
        log:trace("Preset data: " .. json.encode(data))
        return data
    else
        log:error("Failed to load preset: " .. id)
        return nil
    end
end

-- Получить список опций для выпадающего списка.
function presets.getOptions()
    local list = presets.getFileList()
    local options = {}
    for _, id in ipairs(list) do
        local data = presets.loadPresetData(id)
        if data then
            table.insert(options, {
                label = data.presetName or id,
                value = id
            })
        end
    end
    return options
end

-- Сохранить пресет.
function presets.save(presetName)
    local data = {}
    local keys = {
        "sephIntegration", "HUDPositionX", "HUDPositionY", "healthBarPos", "showValuesHealth", "healthBarWidth", "healthBarHeight", "magickaBar", "showValuesMagicka", "magickaBarWidth", "magickaBarHeight", "fatigueBar", "showValuesFatigue", "fatigueBarWidth", "fatigueBarHeight", "HUDBackgroundAlpha", "weaponSlot", "SlotIconSize", "iconBackgroundAlpha", "weaponSlotPos", "blockSpacing", "weaponSlotAlignY", "barBlockAlignY"
    }
    for _, key in ipairs(keys) do
        data[key] = config.mcm[key]
    end
    data.presetName = presetName
    
    mwse.saveConfig(config.presetPath .. "/" .. presetName, data)
    loadedPresets[presetName] = data
    return true
end

-- Загрузить пресет.
function presets.load()
    local data = presets.loadPresetData(config.mcm.selectedPreset)
    if data then
        for key, value in pairs(data) do
            if config.mcmDefault[key] ~= nil then
                config.mcm[key] = value
            end
        end
        mwse.saveConfig(config.configPath, config.mcm)
        return true
    end
    return false
end

-- Удалить пресет.
function presets.delete(id)
    local path = "Data Files\\MWSE\\config\\" .. config.presetPath .. "\\" .. id .. ".json"
    os.remove(path)
    loadedPresets[id] = nil
end

return presets