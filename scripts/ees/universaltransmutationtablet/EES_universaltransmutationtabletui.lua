require "/scripts/ees/common/EES_transmutation_study.lua"
require "/scripts/ees/common/EES_transmutation_craft.lua"
require "/scripts/ees/common/EES_transmutation_search.lua"
require "/scripts/ees/common/EES_transmutation_emccalc.lua"
require "/scripts/ees/common/EES_transmutation_stack.lua"
require "/scripts/ees/EES_utils.lua"

--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_superInit = init
function init()
  if EES_superInit then EES_superInit() end

  self.mainEmc = config.getParameter("eesMainEmc")

  -- Initiallize the crafting grid
  refreshEmcChange()
end

-- Hook function called when the GUI is closed.
EES_superUninit = uninit
function uninit()
  if EES_superUninit then EES_superUninit() end

  -- Dump all the items out of the book.
  dumpItems()
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

function swapItem(widgetName)
  local slotItem = widget.itemSlotItem(widgetName)
  local swapItem = player.swapSlotItem()

  if not swapItem or self.canStudy[swapItem.name] then
    if not slotItem or not swapItem or swapItem.name ~= slotItem.name then
      -- Items are different, swap them.
      player.setSwapSlotItem(slotItem)
      widget.setItemSlotItem(widgetName, swapItem)
    else
      -- Items are the same, stack them.
      player.setSwapSlotItem(
        EES_applyItemAtSlot(swapItem, string.sub(widgetName, -1))
      )
    end
  else
    pane.playSound("/sfx/interface/clickon_error.ogg")
  end

  -- Re-calculate and display the "studyEmc" value
  widget.setText("labelStudyEmc", EES_calculateStudyEmcValue())
end

function changeEmcRadioGroup(index)
  if index == "0" then
    self.mainEmc = "EES_mineemc"
    EES_refreshStudyList({mine = {"T1", "T2", "T3"}})
  elseif index == "1" then
    self.mainEmc = "EES_farmemc"
    EES_refreshStudyList({farm = {"T1", "T2", "T3"}})
  elseif index == "2" then
    self.mainEmc = "EES_huntemc"
    EES_refreshStudyList({hunt = {"T1", "T2", "T3"}})
  end

  dumpItems()
  refreshEmcChange()
end
--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

-- Get "configName" from the config.
-- Abstracts object/activeItem/scriptedPane diferencies.
function EES_getConfig(configName)
  return config.getParameter(configName)
end

-- Gets the item in the specified slot.
-- Abstracts container/itemGrid/itemSlot diferencies.
function EES_getItemAtSlot(slot)
  return widget.itemSlotItem("itemSlot" .. slot)
end

-- Sets the item in the specified slot.
-- Abstracts container/itemGrid/itemSlot diferencies.
function EES_setItemAtSlot(item, slot)
  widget.setItemSlotItem("itemSlot" .. slot, item)
end

-- Add the specified items to the given slot, returning the leftover.
-- Abstracts container/itemGrid/itemSlot diferencies.
function EES_applyItemAtSlot(itemToApply, slot)
  local slotItem = EES_getItemAtSlot(slot)

  if not slotItem then
    -- Slot is empty, move all the items and return.
    EES_setItemAtSlot(itemToApply, slot)
    return nil
  elseif itemToApply.name ~= slotItem.name then
    -- Only items of the same type can be stacked, do nothing.
    return itemToApply
  else
    -- Calculate how many items we can add.
    local slotItemConfig = root.itemConfig(slotItem).config
    local maxStack = (slotItemConfig.category and slotItemConfig.category == "Blueprint" and 1) or slotItemConfig.maxStack or root.assetJson("/items/defaultParameters.config:defaultMaxStack")
    local missing = maxStack - slotItem.count
    local amountToAdd = math.min(missing, itemToApply.count)

    -- Add the amount to the slot.
    slotItem.count = slotItem.count + amountToAdd
    EES_setItemAtSlot(slotItem, slot)

    -- Return the items we were unable to fit.
    itemToApply.count = itemToApply.count - amountToAdd
    return itemToApply.count ~= 0 and itemToApply or nil
  end
end

-- Updates the labels for the player EMC with the current player EMC.
function EES_updatePlayerEmcLabels()
  widget.setText("labelMainEmc", player.currency(self.mainEmc))
  widget.setText("labelUniversalEmc", player.currency("EES_universalemc"))
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

function refreshEmcChange()
  -- Initiallize player emc
  widget.setImage("iconMainEmc", "/items/EES/currency/" .. self.mainEmc .. ".png")
  EES_updatePlayerEmcLabels()

  -- Initiallize the crafting grid
  EES_refreshAllCrafting()
end

-- Dump all the items out of the book.
function dumpItems()
  for studySlot = self.initStudySlots, self.endStudySlots do
    local slotItem = EES_getItemAtSlot(studySlot)
		if slotItem then player.giveItem(slotItem) end
    EES_setItemAtSlot(nil, studySlot)
  end
end
