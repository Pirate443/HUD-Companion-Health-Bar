local i18n = mwse.loadTranslations("Pirate.HUD Companion Health Bar")
local config = require("Pirate.HUD Companion Health Bar.config")
local presets = require("Pirate.HUD Companion Health Bar.presets")
local log = mwse.Logger.new()
local mcm = {}

local presetData = {
    presetName = ""
}

local weaponSlotPosDropdown
local HealthBarPosDropdown
local presetNameInput
local presetDropdown
local weaponSlotAlignYDropdown
local barBlockAlignYDropdown

local function addSideBar(component)
    component.sidebar:createCategory(i18n("mcm.modname")..i18n("mcm.version")..(config.modVersion or (i18n("mcm.metadata.eror"))))
    component.sidebar:createInfo{ text = i18n("mcm.ModDescription") }

    local linksCategory = component.sidebar:createCategory(i18n("mcm.Links"))
    linksCategory:createHyperLink{
        text = i18n("mcm.Nexus"),
        url = "https://www.nexusmods.com/morrowind/mods/60242"
    }
    linksCategory:createHyperLink{
        text = i18n("mcm.FullRest"),
        url = "https://www.fullrest.ru/files/interfeys-zdorovya-kompanonov"
    }
    linksCategory:createHyperLink{
        text = i18n("mcm.TESAll"),
        url = "https://tesall.ru/files/file/14646-interfeys-zdorovya-kompanonov/"
    }

    local creditsCategory = component.sidebar:createCategory(i18n("mcm.Credits"))
    creditsCategory:createHyperLink{
        text = i18n("mcm.Pirate"),
        url = "https://www.nexusmods.com/profile/Pirate443",
    }
    creditsCategory:createHyperLink{
        text = i18n("mcm.Spammer21"),
        url = "https://www.nexusmods.com/profile/Spammer21",
    }
    creditsCategory:createHyperLink{
        text = i18n("mcm.Mesafoo"),
        url = "https://www.nexusmods.com/profile/mesafoo",
    }

    --creditsCategory:createInfo{ text = credit.text }
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = i18n("mcm.modname"),
    --headerImagePath = "textures/headerImageName.dds"
    }

    template.onClose = function ()
        mwse.saveConfig(config.configPath, config.mcm)
        mcm.updateOptions()
    end
    --template:saveOnClose(config.configPath, config.mcm)
    template:register()
        
    local page = template:createSideBarPage { label = i18n("mcm.generalSettings"), showReset = true, showDefaultSetting = true }
    addSideBar(page)

    local displayHUDCompanion = page:createCategory{
    label = i18n("mcm.HealthBars.label"),
    description = i18n("mcm.HealthBars.desc"),
    }

    if tes3.isLuaModActive("seph.hudCustomizer") then
        displayHUDCompanion:createYesNoButton {
            label = i18n("mcm.seph.YesNo.label"),
            description = i18n("mcm.seph.YesNo.desc"),
            defaultSetting = config.mcmDefault.sephIntegration,
            restartRequired = true,
            variable = mwse.mcm.createTableVariable{ id = "sephIntegration", table = config.mcm }
        }
    end

    displayHUDCompanion:createSlider{
        label = i18n("mcm.HUD.PosX.label") .. " %s%%",
        description = i18n("mcm.HUD.PosX.desc"),
        defaultSetting = config.mcmDefault.HUDPositionX,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "HUDPositionX", table = config.mcm},
        callback = function()
            mcm.updatePosition()
        end
    }

    displayHUDCompanion:createSlider{
        label = i18n("mcm.HUD.PosY.label") .. " %s%%",
        description = i18n("mcm.HUD.PosY.desc"),
        defaultSetting = config.mcmDefault.HUDPositionY,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "HUDPositionY", table = config.mcm},
        callback = function()
            mcm.updatePosition()
        end
    }

    local UpdateHealthBars = page:createCategory{
    label = i18n("mcm.UpdateHealthBars.label"),
    description = i18n("mcm.UpdateHealthBars.desc"),
    }

    UpdateHealthBars:createSlider{
        label = i18n("mcm.UpdateInterval.label") .. " %s " .. i18n("mcm.MS"),
        description = i18n("mcm.UpdateInterval.desc"),
        defaultSetting = config.mcmDefault.pollRate,
        min = 1,
        max = 5,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{id = "pollRate", table = config.mcm}
    }

    UpdateHealthBars:createOnOffButton {
        label = i18n("mcm.eventUpdate.label"),
        description = i18n("mcm.eventUpdate.desc"),
        defaultSetting = config.mcmDefault.enableEvents,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "enableEvents", table = config.mcm }
    }

    local presetsCategory = page:createCategory{
        label = i18n("mcm.presets.cat.label"),
        description = i18n("mcm.presets.cat.desc"),
    }

    presetDropdown = presetsCategory:createDropdown{
        label = i18n("mcm.presets.select.label"),
        description = i18n("mcm.presets.select.desc"),
        defaultSetting = config.mcmDefault.selectedPreset,
        options = presets.getOptions(),
        variable = mwse.mcm.createTableVariable{ id = "selectedPreset", table = config.mcm }
    }

    presetsCategory:createButton{
        buttonText = i18n("mcm.presets.load.label"),
        description = i18n("mcm.presets.load.desc"),
        callback = function()
            presets.load()
            mcm.updatePosition()
            mcm.updateBarBgAlpha()
            mcm.updateBgAlpha()
            mcm.updateIconBgAlpha()
            mcm.updateShowValues()
            mcm.updateSlotPosition()
            mcm.updateWeaponSlotAlign()
            mcm.updateBarBlockAlign()
            mcm.updateHUDSize()
            if weaponSlotPosDropdown then
                weaponSlotPosDropdown.selectedOption = nil
            end
            if HealthBarPosDropdown then
                HealthBarPosDropdown.selectedOption = nil
            end
            if weaponSlotAlignYDropdown then
                weaponSlotAlignYDropdown.selectedOption = nil
            end
            if barBlockAlignYDropdown then
                barBlockAlignYDropdown.selectedOption = nil
            end
            if presetNameInput then
            local data = presets.loadPresetData(config.mcm.selectedPreset)
                presetNameInput.variable.value = data.presetName
            end
            if template and page then
                template:clickTab(page)
            end
        end
    }

    presetNameInput = presetsCategory:createTextField{
        label = i18n("mcm.presets.name.label"),
        description = i18n("mcm.presets.name.desc"),
        variable = mwse.mcm.createTableVariable{ id = "presetName", table = presetData },
    }

    presetsCategory:createButton{
        buttonText = i18n("mcm.presets.save.label"),
        description = i18n("mcm.presets.save.desc"),
        callback = function()
            local presetName = presetNameInput.variable.value or ""
            if presetName == "" then
                tes3ui.showMessageMenu({
                    message = i18n("mcm.presets.save.empty"),
                    buttons = { { text = i18n("mcm.presets.delete.ok") } }
                })
                return
            end
            if presets.isProtected(presetName) then
                tes3ui.showMessageMenu({
                    message = i18n("mcm.presets.save.protected"),
                    buttons = { { text = i18n("mcm.presets.delete.ok") } }
                })
                return
            end
            if presets.save(presetName) then
                tes3.messageBox(i18n("mcm.presets.save.msg") .. " " .. presetName)
                if presetDropdown then
                    presetDropdown.options = presets.getOptions()
                    presetDropdown.selectedOption = nil
                end
                if template and page then
                    template:clickTab(page)
                end
            else
                tes3.messageBox(i18n("mcm.presets.save.error"))
            end
        end
    }

    presetsCategory:createButton{
        buttonText = i18n("mcm.presets.delete.label"),
        description = i18n("mcm.presets.delete.desc"),
        callback = function()
            local presetName = presetDropdown.variable.value or ""
            if presetName == "" then
                tes3ui.showMessageMenu({
                    message = i18n("mcm.presets.delete.notfound"),
                    buttons = { { text = i18n("mcm.presets.delete.ok") } }
                })
                return
            end
            if presets.isProtected(presetName) then
                tes3ui.showMessageMenu({
                    message = i18n("mcm.presets.delete.protected"),
                    buttons = { { text = i18n("mcm.presets.delete.ok") } }
                })
                return
            end
            tes3ui.showMessageMenu({
                message = i18n("mcm.presets.delete.confirm") .. " " .. presetName .. "?",
                buttons = {
                    {
                        text = i18n("mcm.presets.delete.yes"),
                        callback = function()
                            presets.delete(presetName)
                            if presetDropdown then
                                presetDropdown.options = presets.getOptions()
                                presetDropdown.selectedOption = nil
                            end
                            if presetNameInput then
                                presetNameInput.variable.value = ""
                            end
                            if template and page then
                                template:clickTab(page)
                            end
                            tes3.messageBox(i18n("mcm.presets.delete.msg") .. " " .. presetName)
                        end
                    },
                    {
                        text = i18n("mcm.presets.delete.no")
                    }
                }
            })
        end
    }

    local category1 = page:createCategory{
    label = i18n("mcm.category1.label"),
    description = i18n("mcm.category1.desc"),
    }

    HealthBarPosDropdown = category1:createDropdown {
        label = i18n("mcm.HealthBar.Pos.label"),
        description = i18n("mcm.HealthBar.Pos.desc"),
        defaultSetting = config.mcmDefault.healthBarPos,
        options  = {
            { label = i18n("mcm.HealthBar.Pos.combined"), value = "combined" },
            { label = i18n("mcm.HealthBar.Pos.separate"), value = "separate" },
        },
        variable = mwse.mcm.createTableVariable { id = "healthBarPos", table = config.mcm },
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createOnOffButton {
        label = i18n("mcm.showValuesHealth.label"),
        description = i18n("mcm.showValuesHealth.desc"),
        defaultSetting = config.mcmDefault.showValuesHealth,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "showValuesHealth", table = config.mcm },
        callback = function()
            mcm.updateShowValues()
        end
    }

    category1:createSlider{
        label = i18n("mcm.healthBarWidth.label"),
        description = i18n("mcm.healthBarWidth.desc"),
        defaultSetting = config.mcmDefault.healthBarWidth,
        restartRequired = false,
        min = 30,
        max = 200,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "healthBarWidth", table = config.mcm},
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createSlider{
        label = i18n("mcm.healthBarHeight.label"),
        description = i18n("mcm.healthBarHeight.desc"),
        defaultSetting = config.mcmDefault.healthBarHeight,
        restartRequired = false,
        min = 5,
        max = 32,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "healthBarHeight", table = config.mcm},
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createOnOffButton {
        label = i18n("mcm.magickaBar.label"),
        description = i18n("mcm.magickaBar.desc"),
        defaultSetting = config.mcmDefault.magickaBar,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "magickaBar", table = config.mcm },
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createOnOffButton {
        label = i18n("mcm.showValuesMagicka.label"),
        description = i18n("mcm.showValuesMagicka.desc"),
        defaultSetting = config.mcmDefault.showValuesMagicka,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "showValuesMagicka", table = config.mcm },
        callback = function()
            mcm.updateShowValues()
        end
    }

    category1:createSlider{
        label = i18n("mcm.magickaBarWidth.label"),
        description = i18n("mcm.magickaBarWidth.desc"),
        defaultSetting = config.mcmDefault.magickaBarWidth,
        restartRequired = false,
        min = 30,
        max = 200,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "magickaBarWidth", table = config.mcm},
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createSlider{
        label = i18n("mcm.magickaBarHeight.label"),
        description = i18n("mcm.magickaBarHeight.desc"),
        defaultSetting = config.mcmDefault.magickaBarHeight,
        restartRequired = false,
        min = 5,
        max = 32,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "magickaBarHeight", table = config.mcm},
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createOnOffButton {
        label = i18n("mcm.fatigueBar.label"),
        description = i18n("mcm.fatigueBar.desc"),
        defaultSetting = config.mcmDefault.fatigueBar,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "fatigueBar", table = config.mcm },
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createOnOffButton {
        label = i18n("mcm.showValuesFatigue.label"),
        description = i18n("mcm.showValuesFatigue.desc"),
        defaultSetting = config.mcmDefault.showValuesFatigue,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "showValuesFatigue", table = config.mcm },
        callback = function()
            mcm.updateShowValues()
        end
    }

    category1:createSlider{
        label = i18n("mcm.fatigueBarWidth.label"),
        description = i18n("mcm.fatigueBarWidth.desc"),
        defaultSetting = config.mcmDefault.fatigueBarWidth,
        restartRequired = false,
        min = 30,
        max = 200,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "fatigueBarWidth", table = config.mcm},
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createSlider{
        label = i18n("mcm.fatigueBarHeight.label"),
        description = i18n("mcm.fatigueBarHeight.desc"),
        defaultSetting = config.mcmDefault.fatigueBarHeight,
        restartRequired = false,
        min = 5,
        max = 32,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "fatigueBarHeight", table = config.mcm},
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createSlider{
        label = i18n("mcm.Bar.BgAlpha.label") .. " %s%%",
        description = i18n("mcm.Bar.BgAlpha.desc"),
        defaultSetting = config.mcmDefault.BarBackgroundAlpha,
        restartRequired = false,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "BarBackgroundAlpha", table = config.mcm },
        callback = function()
            mcm.updateBarBgAlpha()
        end
    }

    category1:createSlider{
        label = i18n("mcm.HUD.BgAlpha.label") .. " %s%%",
        description = i18n("mcm.HUD.BgAlpha.desc"),
        defaultSetting = config.mcmDefault.HUDBackgroundAlpha,
        restartRequired = false,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "HUDBackgroundAlpha", table = config.mcm },
        callback = function()
            mcm.updateBgAlpha()
        end
    }

    category1:createOnOffButton {
        label = i18n("mcm.weaponSlot.OnOff.label"),
        description = i18n("mcm.weaponSlot.OnOff.desc"),
        defaultSetting = config.mcmDefault.weaponSlot,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{ id = "weaponSlot", table = config.mcm },
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createSlider{
        label = i18n("mcm.SloticonSize.label"),
        description = i18n("mcm.SloticonSize.desc"),
        defaultSetting = config.mcmDefault.SlotIconSize,
        restartRequired = false,
        min = 20,
        max = 96,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "SlotIconSize", table = config.mcm},
        callback = function()
            mcm.updateHUDSize()
        end
    }

    category1:createSlider{
        label = i18n("mcm.icon.BgAlpha.label") .. " %s%%",
        description = i18n("mcm.icon.BgAlpha.desc"),
        defaultSetting = config.mcmDefault.iconBackgroundAlpha,
        restartRequired = false,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "iconBackgroundAlpha", table = config.mcm },
        callback = function()
            mcm.updateIconBgAlpha()
        end
    }

    weaponSlotPosDropdown = category1:createDropdown {
        label = i18n("mcm.weaponSlot.Pos.label"),
        description = i18n("mcm.weaponSlot.Pos.desc"),
        defaultSetting = config.mcmDefault.weaponSlotPos,
        options  = {
            { label = i18n("mcm.weaponSlot.Pos.left"), value = "left" },
            { label = i18n("mcm.weaponSlot.Pos.right"), value = "right" },
        },
        variable = mwse.mcm.createTableVariable { id = "weaponSlotPos", table = config.mcm },
        callback = function()
            mcm.updateSlotPosition()
        end
    }

    category1:createSlider{
        label = i18n("mcm.block.Spacing.label"),
        description = i18n("mcm.block.Spacing.desc"),
        defaultSetting = config.mcmDefault.blockSpacing,
        min = 0,
        max = 5,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{id = "blockSpacing", table = config.mcm},
        callback = function()
            mcm.updateHUDSize()
        end
    }

    weaponSlotAlignYDropdown = category1:createDropdown {
        label = i18n("mcm.weaponSlot.AlignY.label"),
        description = i18n("mcm.weaponSlot.AlignY.desc"),
        defaultSetting = config.mcmDefault.weaponSlotAlignY,
        options  = {
            { label = i18n("mcm.weaponSlot.AlignY.top"), value = 0 },
            { label = i18n("mcm.weaponSlot.AlignY.center"), value = 0.5 },
            { label = i18n("mcm.weaponSlot.AlignY.bottom"), value = 1 },
        },
        variable = mwse.mcm.createTableVariable { id = "weaponSlotAlignY", table = config.mcm },
        callback = function()
            mcm.updateWeaponSlotAlign()
        end
    }

    barBlockAlignYDropdown = category1:createDropdown {
        label = i18n("mcm.barBlock.AlignY.label"),
        description = i18n("mcm.barBlock.AlignY.desc"),
        defaultSetting = config.mcmDefault.barBlockAlignY,
        options  = {
            { label = i18n("mcm.barBlock.AlignY.top"), value = 0 },
            { label = i18n("mcm.barBlock.AlignY.center"), value = 0.5 },
            { label = i18n("mcm.barBlock.AlignY.bottom"), value = 1 },
        },
        variable = mwse.mcm.createTableVariable { id = "barBlockAlignY", table = config.mcm },
        callback = function()
            mcm.updateBarBlockAlign()
        end
    }

    local miscSetting = page:createCategory{
    label = i18n("mcm.debug.label"),
    description = i18n("mcm.debug.desc"),
    }

    miscSetting:createLogLevelOptions{
        defaultSetting = config.mcmDefault.logLevel,
        variable = mwse.mcm.createTableVariable{id = "logLevel", table = config.mcm},
        callback = function(self)
            log.level = self.variable.value
        end
    }

    template:createExclusionsPage{
        label = i18n("mcm.CompanionBlacklist.label"),
        description = i18n("mcm.CompanionBlacklist.desc"),
        leftListLabel = i18n("mcm.CompanionBlacklist.left"),
        rightListLabel = i18n("mcm.CompanionBlacklist.right"),
        showAllBlocked = true,
        variable = mwse.mcm.createTableVariable{ id = "blackList", table = config.mcm },
        filters = {
            {
                label = i18n("mcm.CompanionBlacklist.right"),
                callback = function()
                    local list = {}
                    local macp = tes3.mobilePlayer
                    if (macp) then
                        for actor in tes3.iterate(macp.friendlyActors) do
                            if (actor ~= macp) then
                                local reference = actor.reference
                                local id = reference.id
                                if (reference.object.isInstance) then
                                    id = reference.object.baseObject.id
                                end
                                table.insert(list, id)
                            end
                        end
                    end
                    return list
                end
            },
        }
    }

end
event.register("modConfigReady", registerMCM)

return mcm