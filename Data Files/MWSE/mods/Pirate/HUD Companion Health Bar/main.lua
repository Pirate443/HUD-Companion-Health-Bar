--[[
	Mod Name: Companion Health Bars
	Author: mesafoo
	Nexus URL: https://www.nexusmods.com/morrowind/mods/46136
	Description: Adds health bars for your companions to the in-game HUD.
	Credits: NullCascade, Hrnchamd, and all the others that have worked on MWSE, MGE and the MCP over the years. Hrnchamd's UI Inspector which was a big help in making this happen.
	NullCascade again for the companion detection, blacklist, and MCM menu code I used. And the very generous MIT license his mods are released under.
	And a big thanks to all the friendly and helpful people on the Morrowind Modding Community discord.
]]

local i18n = mwse.loadTranslations("Pirate.HUD Companion Health Bar")
local config = require("Pirate.HUD Companion Health Bar.config")
local cf = require("Pirate.HUD Companion Health Bar.config").mcm
local log = mwse.Logger.new{
    modName = i18n("mcm.modname"),
    level   = config.mcm.logLevel
}
local mcm = require("Pirate.HUD Companion Health Bar.mcm")
local seph = include("seph.hudCustomizer.interop")
local hudCompanionId = tes3ui.registerID("HUD_Companion")
local menuCompanion

--The table that will hold most of our information
local companionHealthBars = {}

local function calculateSizes()
    -- Ширина блока шкал (максимальная из видимых шкал)
    local BarWidth = 0
    if cf.healthBarPos == "combined" and cf.healthBarWidth then BarWidth = math.max(BarWidth, cf.healthBarWidth) end
    if cf.magickaBar and cf.magickaBarWidth then BarWidth = math.max(BarWidth, cf.magickaBarWidth) end
    if cf.fatigueBar and cf.fatigueBarWidth then BarWidth = math.max(BarWidth, cf.fatigueBarWidth) end
    -- Высота блока шкал (сумма высот видимых шкал)
    local BarHeight = 0
    if cf.healthBarPos == "combined" and cf.healthBarHeight then BarHeight = BarHeight + cf.healthBarHeight end
    if cf.magickaBar and cf.magickaBarHeight then BarHeight = BarHeight + cf.magickaBarHeight end
    if cf.fatigueBar and cf.fatigueBarHeight then BarHeight = BarHeight + cf.fatigueBarHeight end
    -- Ширина общего блока (если слот выключен)
    local blockWidth = BarWidth + cf.blockSpacing*2
    -- размеры слота (если слот выключен)
    local SlotWidth = 0
    local SlotHeight = 0
    -- Ширина шкалы здоровья в режиме отдельного блока (если слот выключен)
    local AltBarWidth = cf.healthBarWidth
    if cf.weaponSlot then
        -- размеры слота (если слот включен)
        SlotWidth = cf.SlotIconSize + config.BorderSize * 2
        SlotHeight = cf.SlotIconSize + config.BorderSize * 2
        -- Ширина общего блока (если слот включен)
        blockWidth = blockWidth + SlotWidth + cf.blockSpacing * 2
        -- Ширина шкалы здоровья в режиме separate (если слот включен)
        AltBarWidth = cf.healthBarWidth + SlotWidth + cf.blockSpacing*2
    end
    return {
        BarWidth = BarWidth,
        BarHeight = BarHeight,
        blockWidth = blockWidth,
        SlotWidth = SlotWidth,
        SlotHeight = SlotHeight,
        AltBarWidth = AltBarWidth,
    }
end

local function inBlackList(actor)
	local reference = actor.reference

	--Get the ID. If we're looking at an instance, check against the base object instead.
	local id = reference.id
	if (reference.object.isInstance) then
		id = reference.object.baseObject.id
	end
	--Check blacklist for actor's id and return result
	--return table.find(cf.blackList, id)
return cf.blackList[id]
end

local function validCompanionCheck(mobileActor)
	--The player shouldn't count as his own companion.
	if (mobileActor == tes3.mobilePlayer) then
		return false
	end
	--Make sure the friendly actor is currently following player.
	if (tes3.getCurrentAIPackageId(mobileActor) ~= tes3.aiPackage.follow) then
		return false
	end
	--Respect the blacklist.
	if (inBlackList(mobileActor)) then
		return false
	end
	--Make sure we don't get dead actors.
	local animState = mobileActor.actionData.animationAttackState
	if (mobileActor.health.current <= 0 or animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
		return false
	end

	return true
end

local function updateAllHealthBarValues()
	--Iterate over and refresh bars with updated values
	for _, companionBar in pairs(companionHealthBars.healthBars) do
		local companionRef = companionBar.companionRef
		local bar0Widget = companionBar.barMenu0.widget
		local barWidget = companionBar.barMenu.widget
		local bar2Widget = companionBar.barMenu2.widget
		local bar3Widget = companionBar.barMenu3.widget
		local image = companionBar.image
		if not companionRef and not companionRef.mobile then return end
		local npcHealth = companionRef and companionRef.mobile and companionRef.mobile.health
		local npcMagicka = companionRef and companionRef.mobile and companionRef.mobile.magicka
		local npcFatigue = companionRef and companionRef.mobile and companionRef.mobile.fatigue
		companionBar.barMenu0.visible = cf.healthBarPos == "separate"
		companionBar.barMenu.visible = cf.healthBarPos == "combined"
		companionBar.barMenu2.visible = cf.magickaBar
		companionBar.barMenu3.visible = cf.fatigueBar
		if not barWidget then return end
        bar0Widget.max = npcHealth.base
		bar0Widget.current = npcHealth.current
		barWidget.max = npcHealth.base
		barWidget.current = npcHealth.current
		bar2Widget.max = npcMagicka.base
		bar2Widget.current = npcMagicka.current
		bar3Widget.max = npcFatigue.base
		bar3Widget.current = npcFatigue.current
        local image1 = companionBar.image1
        local image2 = companionBar.image2
		local weapon = companionRef.mobile.readiedWeapon
		local magic1 = companionRef.mobile.currentEnchantedItem
		local magic2 = companionRef.mobile.currentSpell
        if weapon and weapon.object and weapon.object.enchantment then
            image1.contentPath = "Textures\\menu_icon_magic_mini.tga"
            image1.visible = true
            image2.contentPath = "Icons\\"..weapon.object.icon
            image2.visible = true
        elseif weapon and weapon.object then
            image1.visible = false
            image2.contentPath = "Icons\\"..weapon.object.icon
            image2.visible = true
        elseif magic1 and magic1.object then
            image1.contentPath = "Textures\\menu_icon_magic_mini.tga"
            image1.visible = true
            image2.contentPath = "Icons\\"..magic1.object.icon
            image2.visible = true
        elseif magic2 then
            image1.visible = false
            image2.contentPath = "Icons\\"..magic2.effects[1].object.bigIcon
            image2.visible = true
        else
            image1.visible = false
            image2.contentPath = "Icons\\k\\Stealth_HandToHand.tga"
            image2.visible = true
        end
        image.parent.visible = cf.weaponSlot
	end
end

local function createNewHealthBars(companions)
    local sizes = calculateSizes()
    local BarWidth   = sizes.BarWidth
    local BarHeight  = sizes.BarHeight
    local blockWidth = sizes.blockWidth
    local SlotWidth  = sizes.SlotWidth
    local SlotHeight = sizes.SlotHeight
    local AltBarWidth = sizes.AltBarWidth
	--Iterate through the list of companions that don't currently have a health bar
	for i = #companions, 1, -1 do
		local companionRef = companions[i]
		--Create a label with the companion's name to go above the health bar
		local labelMenuID = tes3ui.registerID("CompanionHealthBars:"..companionRef.id..".label")
		local labelMenu = companionHealthBars.mainHealthBarMenu.menu:createBlock({id = labelMenuID})
		--labelMenu.minWidth = 200
		labelMenu.autoWidth = true
		labelMenu.autoHeight = true
		labelMenu.flowDirection = "left_to_right"
		local text = labelMenu:createLabel{
			text = companionRef.object.name
		}
		--Add a top border to create some space between individual bars
		text.borderTop = 2
		--Create a bar with the companion's current/max health
		local healthBarMenuID = tes3ui.registerID("CompanionHealthBars:"..companionRef.id..".bar")

        -- блок для шкалы здоровья в режиме separate
        local blockHealth = companionHealthBars.mainHealthBarMenu.menu:createBlock()
        blockHealth.autoWidth = true
        blockHealth.autoHeight = true
        local healthBarMenuAlt = blockHealth:createRect():createFillBar{
            id = healthBarMenuID.."0",
            current = companionRef.mobile.health.current,
            max = companionRef.mobile.health.base
        }
        healthBarMenuAlt.parent.alpha = 0.8
        healthBarMenuAlt.parent.borderAllSides = cf.blockSpacing
        healthBarMenuAlt.parent.borderTop = 1
        healthBarMenuAlt.parent.width = AltBarWidth
        healthBarMenuAlt.parent.height = cf.healthBarHeight
        healthBarMenuAlt.parent.visible = cf.healthBarPos == "separate"
        --healthBarMenuAlt.borderAllSides = cf.blockSpacing
        --healthBarMenuAlt.borderTop = 1
        healthBarMenuAlt.width = AltBarWidth
        healthBarMenuAlt.height = cf.healthBarHeight
        healthBarMenuAlt.widget.showText = cf.showValuesHealth
        --healthBarMenuAlt.visible = cf.healthBarPos == "separate"
		local block = companionHealthBars.mainHealthBarMenu.menu:createBlock()
        block.width = blockWidth
        block.height = math.max(BarHeight, SlotHeight) + cf.blockSpacing * 2
		block.flowDirection = "left_to_right"
		local block2 = block:createBlock()
        block2.width = BarWidth
        block2.height = BarHeight
        block2.absolutePosAlignY = cf.barBlockAlignY
		block2.flowDirection = "top_to_bottom"
        block2.borderAllSides = cf.blockSpacing
		local healthBarMenu = block2:createFillBar{
			id = healthBarMenuID,
			current = companionRef.mobile.health.current,
			max = companionRef.mobile.health.base
		}
		local magickaBarMenu = block2:createFillBar{
			id = healthBarMenuID.."m",
			current = companionRef.mobile.magicka.current,
			max = companionRef.mobile.magicka.base
		}
		local fatigueBarMenu = block2:createFillBar{
			id = healthBarMenuID.."f",
			current = companionRef.mobile.fatigue.current,
			max = companionRef.mobile.fatigue.base
		}
        healthBarMenu.widget.fillColor = tes3ui.getPalette("health_color")
		healthBarMenu.width = cf.healthBarWidth
		healthBarMenu.height = cf.healthBarHeight
        healthBarMenu.widget.showText = cf.showValuesHealth

		magickaBarMenu.widget.fillColor = tes3ui.getPalette("magic_color")
		magickaBarMenu.width = cf.magickaBarWidth
		magickaBarMenu.height = cf.magickaBarHeight
        magickaBarMenu.widget.showText = cf.showValuesMagicka

		fatigueBarMenu.widget.fillColor = tes3ui.getPalette("fatigue_color")
		fatigueBarMenu.width = cf.fatigueBarWidth
		fatigueBarMenu.height = cf.fatigueBarHeight
        fatigueBarMenu.widget.showText = cf.showValuesFatigue

        -- Weapon Slot
		local image = block:createThinBorder():createRect({id = "CHB_SpaFork_images", color = {0,0,0}})
        image.parent.width = SlotWidth
        image.parent.height = SlotHeight
        image.parent.borderAllSides = cf.blockSpacing
        image.parent.absolutePosAlignY = cf.weaponSlotAlignY
        image.parent.paddingAllSides = config.BorderSize
		image.alpha = cf.iconBackgroundAlpha / 100
        image.scaleMode = true
        image.width = cf.SlotIconSize
        image.height = cf.SlotIconSize
		image.flowDirection = "left_to_right"
		image.absolutePosAlignX = 0.5
        image.absolutePosAlignY = 0.5
        local image1 = image:createImage({})
        image1.visible = false
        image1.scaleMode = true
        image1.width = cf.SlotIconSize
        image1.height = cf.SlotIconSize
        image1.absolutePosAlignX = 0.5
        image1.absolutePosAlignY = 0.5
        local image2 = image:createImage({})
        image2.visible = false
        image2.scaleMode = true
        image2.width = cf.SlotIconSize
        image2.height = cf.SlotIconSize
        image2.absolutePosAlignX = 0.5
        image2.absolutePosAlignY = 0.5
		local weapon = companionRef.mobile.readiedWeapon
		local magic1 = companionRef.mobile.currentEnchantedItem
		local magic2 = companionRef.mobile.currentSpell
        if weapon and weapon.object and weapon.object.enchantment then
            image1.contentPath = "Textures\\menu_icon_magic_mini.tga"
            image1.visible = true
            image2.contentPath = "Icons\\"..weapon.object.icon
            image2.visible = true
        elseif weapon and weapon.object then
            image1.visible = false
            image2.contentPath = "Icons\\"..weapon.object.icon
            image2.visible = true
        elseif magic1 and magic1.object then
            image1.contentPath = "Textures\\menu_icon_magic_mini.tga"
            image1.visible = true
            image2.contentPath = "Icons\\"..magic1.object.icon
            image2.visible = true
        elseif magic2 then
            image1.visible = false
            image2.contentPath = "Icons\\"..magic2.effects[1].object.bigIcon
            image2.visible = true
        else
            image1.visible = false
            image2.contentPath = "Icons\\k\\Stealth_HandToHand.tga"
            image2.visible = true
        end
        image.parent.visible = cf.weaponSlot
        if cf.weaponSlot and cf.weaponSlotPos == "left" then
            block:reorderChildren(0, image.parent, 1)
        end
		companionHealthBars.healthBars[companionRef] = {
			companionRef = companionRef,
			labelMenuID = labelMenuID,
			labelMenu = labelMenu,
			barMenuID = healthBarMenuID,
			barMenu = healthBarMenu,
			barMenu2 = magickaBarMenu,
			barMenu3 = fatigueBarMenu,
			image = image,
            image1 = image1,
            image2 = image2,
            block = block,
            block2 = block2,
            blockHealth = blockHealth,
            barMenu0 = healthBarMenuAlt,
		}
	end
end

local function removeExpiredHealthBars(companionTable)
	--Iterate over all the current health bars we have
	for companionRefID, companionBar in pairs(companionHealthBars.healthBars) do
		local stillValid = false
		for i = #companionTable, 1, -1 do
			--Remove valid companions that already have a bar from the list
			if companionTable[i] == companionBar.companionRef then
				stillValid = true
				table.remove(companionTable, i)
				break
			end
		end
		--Destroy any bars that exist for references that are no longer valid companions
		if stillValid == false then
			local labelMenu = companionHealthBars.mainHUD.menu:findChild(companionBar.labelMenuID)
            local barMenu0 = companionHealthBars.mainHUD.menu:findChild(companionBar.barMenuID.."0")
			local barMenu = companionHealthBars.mainHUD.menu:findChild(companionBar.barMenuID)
			local barMenu2 = companionHealthBars.mainHUD.menu:findChild(companionBar.barMenuID.."m")
			local barMenu3 = companionHealthBars.mainHUD.menu:findChild(companionBar.barMenuID.."f")
			if labelMenu ~= nil and barMenu ~= nil and barMenu0 ~= nil then
				labelMenu:destroy()
                barMenu0.parent:destroy()
				barMenu.parent.parent:destroy()
				--barMenu2:destroy()
				--barMenu3:destroy()
				companionHealthBars.healthBars[companionBar.companionRef] = nil
				--labelMenu = nil
				--barMenu = nil

			else
				log:error("Failed to find and destroy health bar for %q", companionRefID)
			end
		end
	end
end

local function createParentMenu()
	--Create the menu that holds the individual health bars and set some initial settings for it
	local menuID = tes3ui.registerID("CompanionHealthBars:Menu")
	if menuID ~= nil then
		local mainHUDMenu = companionHealthBars.mainHUD.menu
		local menuElement = menuCompanion:createRect{ id = menuID, { 1.0, 1.0, 1.0 } }
		if menuElement ~= nil then
			--Auto adjust dimensions to fit the health bars
			menuElement.autoHeight = true
			menuElement.autoWidth = true

			--Propagate downwards as we add bars
			menuElement.flowDirection = "top_to_bottom"
			--Make it a bit transparent
            menuElement.alpha = cf.HUDBackgroundAlpha / 100
			--Add some padding so it overlaps the bars a bit
			menuElement.paddingAllSides = 4
            if not (seph and cf.sephIntegration) then
			    --Register for the events needed to allow repositioning the menu
			    --Enable mouse capture in case cursor moves off menu while dragging
			    menuElement:registerAfter("mouseDown", function()
				    tes3ui.captureMouseDrag(true)
			    end)
			    --Set menu position to current mouse position while still dragging
			    menuElement:registerAfter("mouseStillPressed", function(e)
				    --Clamping position to account for the ~10px frame at the edges of the screen
				    menuCompanion.absolutePosAlignX = math.clamp(((mainHUDMenu.width * 0.5) + e.data0), 0, mainHUDMenu.width) / mainHUDMenu.width
				    menuCompanion.absolutePosAlignY = 1.0 - math.clamp(((mainHUDMenu.height * 0.5) + e.data1), 0, mainHUDMenu.height) / mainHUDMenu.height
				    mainHUDMenu:updateLayout()
			    end)
			    --Release mouse capture after we're done with it and save the new position
			    menuElement:registerAfter("mouseRelease", function()
				    tes3ui.captureMouseDrag(false)
                    cf.HUDPositionX = menuCompanion.absolutePosAlignX * 100
                    cf.HUDPositionY = menuCompanion.absolutePosAlignY * 100
				    mwse.saveConfig(config.configPath, cf)
			    end)
            end
			--Cache the info in our main table so we don't need to recreate this menu more than needed
			companionHealthBars.mainHealthBarMenu = { id = menuID, menu = menuElement }
		end
	end
	return (companionHealthBars.mainHealthBarMenu ~= nil and companionHealthBars.mainHealthBarMenu.menu ~= nil)
end

local function updateHealthBarMenu(companions)
	--Create our main menu if we don't have one yet
	if companionHealthBars.mainHealthBarMenu ~= nil or createParentMenu() == true then
		--Initialize subtable if it hasn't been already
		companionHealthBars.healthBars = companionHealthBars.healthBars or {}
		--Remove old health bars for invalid companions and cull companions list of companions already with bars
		removeExpiredHealthBars(companions)
		--Create bars for anyone remaining in companion list
		createNewHealthBars(companions)
		--Call updateLayout on the main health bar menu to update for any added/removed bars
		--companionHealthBars.mainHealthBarMenu.menu:updateLayout()
        if companionHealthBars.mainHealthBarMenu and companionHealthBars.mainHealthBarMenu.menu then
            companionHealthBars.mainHealthBarMenu.menu:updateLayout()
        end
		--Update the health values
		updateAllHealthBarValues()
	end
end

local function getMainHUD()
	--Try to get the menu for the game's main HUD that we'll be embedding our menu in
	local hudMenuID = tes3ui.registerID("MenuMulti")
	if hudMenuID ~= nil then
		local hudMenuElement = tes3ui.findMenu(hudMenuID)
		if hudMenuElement ~= nil then
			--Cache it in the main table for later use
			companionHealthBars.mainHUD = { id = hudMenuID, menu = hudMenuElement }
		end
	end
	return (companionHealthBars.mainHUD ~= nil and companionHealthBars.mainHUD.menu ~= nil)
end

local function createHUDCompanion(e)
    if not e.newlyCreated then return end
    menuCompanion = e.element:createRect({ id = hudCompanionId })
    menuCompanion.color = {0.0, 0.0, 0.0}
    menuCompanion.alpha = 0
    menuCompanion.autoWidth = true
    menuCompanion.autoHeight = true
    menuCompanion.flowDirection = "top_to_bottom"
    if not (seph and cf.sephIntegration) then
        menuCompanion.absolutePosAlignX = cf.HUDPositionX / 100
        menuCompanion.absolutePosAlignY = cf.HUDPositionY / 100
    end
end
event.register(tes3.event.uiActivated, createHUDCompanion, { filter = "MenuMulti" })

local companionTable = {}
local function companionCheck()
	--Only update if not in menu mode.
	if tes3ui.menuMode() == false then
		if companionHealthBars.mainHUD ~= nil or getMainHUD() == true then
			--Create a list of player's current valid companions
			for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
				if (validCompanionCheck(mobileActor)) then
					companionTable[#companionTable + 1] = mobileActor.reference
				end
			end
			--Only update things if we found at least one valid companion
			if #companionTable ~= 0 then
				updateHealthBarMenu(companionTable)
				table.clear(companionTable)
			--Otherwise destroy the main health bar menu container and any of its child menus
			elseif companionHealthBars.mainHealthBarMenu ~= nil then
				companionHealthBars.mainHealthBarMenu.menu:destroy()
				companionHealthBars.mainHealthBarMenu = nil
				--Ensure the healthBar table is empty since the validCompanionCheck is occasionally wrong during cell changes
				table.clear(companionHealthBars.healthBars)
				--Update the main HUD
				companionHealthBars.mainHUD.menu:updateLayout()
			end
		else
			log:error("Error getting mainHUD.")
		end
	end
end

--If the actor passed in has a health bar, update the values on it
local function updateHealthBarValues(npcReference)
	--[[local healthBars = companionHealthBars.healthBars
	if healthBars then
		local npcBar = healthBars[npcReference]
		if npcBar then
			local barWidget = npcBar.barMenu.widget
			local npcHealth = npcReference.mobile.health
			barWidget.max = npcHealth.base
			barWidget.current = npcHealth.current
		end
	end]]

    local healthBars = companionHealthBars.healthBars
    if not healthBars then return end
    local npcBar = healthBars[npcReference]
    if not npcBar then return end
    local npcHealth = npcReference.mobile and npcReference.mobile.health
    if not npcHealth then return end

    if npcBar.barMenu and npcBar.barMenu.widget then
        npcBar.barMenu.widget.max = npcHealth.base
        npcBar.barMenu.widget.current = npcHealth.current
    end
    if npcBar.barMenu0 and npcBar.barMenu0.widget then
        npcBar.barMenu0.widget.max = npcHealth.base
        npcBar.barMenu0.widget.current = npcHealth.current
    end

end

--Update health bar values on damage being taken
local function damagedCallback(e)
	updateHealthBarValues(e.reference)
end

--Update health bar values on restore health spelltick
local function spellTickCallback(e)
	if e.effectId == tes3.effect.restoreHealth then
		updateHealthBarValues(e.target)
	end
end

function mcm.updatePosition()
    if seph and cf.sephIntegration then return end
    if menuCompanion then
        menuCompanion.absolutePosAlignX = cf.HUDPositionX / 100
        menuCompanion.absolutePosAlignY = cf.HUDPositionY / 100
        menuCompanion:updateLayout()
    end
end

function mcm.updateBgAlpha()
    if companionHealthBars.mainHealthBarMenu and companionHealthBars.mainHealthBarMenu.menu then
        companionHealthBars.mainHealthBarMenu.menu.alpha = cf.HUDBackgroundAlpha / 100
        companionHealthBars.mainHealthBarMenu.menu:updateLayout()
    end
end

function mcm.updateIconBgAlpha()
    if not companionHealthBars.healthBars then return end
    for _, companionBar in pairs(companionHealthBars.healthBars) do
        if companionBar.image then
            companionBar.image.alpha = cf.iconBackgroundAlpha / 100
        end
    end
end

function mcm.updateShowValues()
    if not companionHealthBars.healthBars then return end
    for _, companionBar in pairs(companionHealthBars.healthBars) do
        if companionBar.barMenu0 then
            companionBar.barMenu0.widget.showText = cf.showValuesHealth
        end
        if companionBar.barMenu then
            companionBar.barMenu.widget.showText = cf.showValuesHealth
        end
        if companionBar.barMenu2 then
            companionBar.barMenu2.widget.showText = cf.showValuesMagicka
        end
        if companionBar.barMenu3 then
            companionBar.barMenu3.widget.showText = cf.showValuesFatigue
        end
    end
end

function mcm.updateSlotPosition()
    if not companionHealthBars.healthBars then return end
    for _, companionBar in pairs(companionHealthBars.healthBars) do
        if companionBar.block then
            if cf.weaponSlot then
                if cf.weaponSlotPos == "left" then
                    companionBar.block:reorderChildren(0, companionBar.image.parent, 1)
                elseif cf.weaponSlotPos == "right" then
                companionBar.block:reorderChildren(2, companionBar.image.parent, 1)
                end
            end
        end
    end
end

function mcm.updateWeaponSlotAlign()
    if not companionHealthBars.healthBars then return end
    for _, companionBar in pairs(companionHealthBars.healthBars) do
        if companionBar.image then
            companionBar.image.parent.absolutePosAlignY = cf.weaponSlotAlignY --0.5
        end
    end
end

function mcm.updateBarBlockAlign()
    if not companionHealthBars.healthBars then return end
    for _, companionBar in pairs(companionHealthBars.healthBars) do
        if companionBar.block2 then
            companionBar.block2.absolutePosAlignY = cf.barBlockAlignY
        end
    end
end

function mcm.updateHUDSize()
    if not companionHealthBars.healthBars then return end

    local sizes = calculateSizes()
    local BarWidth   = sizes.BarWidth
    local BarHeight  = sizes.BarHeight
    local blockWidth = sizes.blockWidth
    local SlotWidth  = sizes.SlotWidth
    local SlotHeight = sizes.SlotHeight
    local AltBarWidth = sizes.AltBarWidth

    for _, companionBar in pairs(companionHealthBars.healthBars) do
        if companionBar.barMenu0 then
            companionBar.barMenu0.parent.borderAllSides = cf.blockSpacing
            companionBar.barMenu0.parent.width = AltBarWidth
            companionBar.barMenu0.parent.height = cf.healthBarHeight
            companionBar.barMenu0.parent.visible = cf.healthBarPos == "separate"
            companionBar.barMenu0.width = AltBarWidth
            companionBar.barMenu0.height = cf.healthBarHeight
            --companionBar.barMenu0.visible = cf.healthBarPos == "separate"
            --companionBar.barMenu0.borderAllSides = cf.blockSpacing
        end
        if companionBar.block then
        companionBar.block.width = blockWidth
        companionBar.block.height = math.max(BarHeight, SlotHeight) + cf.blockSpacing * 2
        end
        if companionBar.block2 then
            companionBar.block2.width = BarWidth
            companionBar.block2.height = BarHeight
            companionBar.block2.borderAllSides = cf.blockSpacing
        end
        if companionBar.barMenu then
            companionBar.barMenu.width = cf.healthBarWidth
            companionBar.barMenu.height = cf.healthBarHeight
            companionBar.barMenu.visible = cf.healthBarPos == "combined"
        end
        if companionBar.barMenu2 then
            companionBar.barMenu2.width = cf.magickaBarWidth
            companionBar.barMenu2.height = cf.magickaBarHeight
            companionBar.barMenu2.visible = cf.magickaBar
        end
        if companionBar.barMenu3 then
            companionBar.barMenu3.width = cf.fatigueBarWidth
            companionBar.barMenu3.height = cf.fatigueBarHeight
            companionBar.barMenu3.visible = cf.fatigueBar
        end
        if companionBar.image then
            companionBar.image.width = cf.SlotIconSize
            companionBar.image.height = cf.SlotIconSize
            companionBar.image.parent.width = SlotWidth
            companionBar.image.parent.height = SlotHeight
            companionBar.image.parent.visible = cf.weaponSlot
            companionBar.image.parent.borderAllSides = cf.blockSpacing
        end
        if companionBar.image1 then
            companionBar.image1.width = cf.SlotIconSize
            companionBar.image1.height = cf.SlotIconSize
            companionBar.image1.scaleMode = true
        end
        if companionBar.image2 then
            companionBar.image2.width = cf.SlotIconSize
            companionBar.image2.height = cf.SlotIconSize
            companionBar.image2.scaleMode = true
        end
    end
end

local companionCheckTimer
local eventsRegistered = false
--Function for reinitializing our timer and events. Called on initial game loaded event and after our mcm menu is closed to reflect any potential option changes
function mcm.updateOptions()
    log:info("updateOptions called")
	if companionCheckTimer ~= nil then
		companionCheckTimer:cancel()
	end
	companionCheckTimer = timer.start({ duration = cf.pollRate, callback = companionCheck, iterations = -1 })

	if not cf.enableEvents and eventsRegistered == true then
		event.unregister("damaged", damagedCallback)
		event.unregister("spellTick", spellTickCallback)
		eventsRegistered = false
	elseif cf.enableEvents and eventsRegistered == false then
		event.register("damaged", damagedCallback)
		event.register("spellTick", spellTickCallback)
		eventsRegistered = true
	end
    mcm.updatePosition()
    mcm.updateBgAlpha()
    mcm.updateIconBgAlpha()
    mcm.updateShowValues()
    mcm.updateSlotPosition()
    mcm.updateWeaponSlotAlign()
    mcm.updateBarBlockAlign()
    mcm.updateHUDSize()
end

local function initialized()
    if seph and cf.sephIntegration then
        seph:registerElement(
        "HUD_Companion",
        i18n("mcm.modname"),
        {
        positionX = 0,
        positionY = 0,
        visible = true
        },
        {
        position = true,
        --visibility = true,
        })
    end

    event.register("loaded", mcm.updateOptions)
    event.register("load", (function() table.clear(companionHealthBars) end))

    log:info("Version: "..config.modVersion.." Initialized!")
end
event.register("initialized", initialized)