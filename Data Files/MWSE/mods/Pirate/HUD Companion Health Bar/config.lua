local config = {}
config.modVersion = "1.0"
config.configPath = "HUD_Companion_Health_Bar"
config.presetPath = "HUD_Companion_Preset"
config.BorderSize = 2
config.mcmDefault = {
    logLevel = 3,
    sephIntegration = true,
    HUDPositionX = 0,
    HUDPositionY = 0,
    pollRate = 1,
    enableEvents = true,
    selectedPreset = "Pirate v1 Compact",
    healthBarPos = "combined", -- combined or separate
    showValuesHealth = true,
    healthBarWidth = 100,
    healthBarHeight = 20,
    magickaBar = true,
    showValuesMagicka = false,
    magickaBarWidth = 80,
    magickaBarHeight = 12,
    fatigueBar = true,
    showValuesFatigue = false,
    fatigueBarWidth = 60,
    fatigueBarHeight = 12,
    BarBackgroundAlpha = 60,
    HUDBackgroundAlpha = 0,
    weaponSlot = true,
    SlotIconSize = 40,
    iconBackgroundAlpha = 60,
    weaponSlotPos = "left", -- right or left
    blockSpacing = 2,
    weaponSlotAlignY = 0.5, -- 0 = top, 0.5 = center, 1 = bottom
    barBlockAlignY = 0.5, -- 0 = top, 0.5 = center, 1 = bottom
    blackList = {}
    }
config.mcm = mwse.loadConfig(config.configPath, config.mcmDefault)
return config