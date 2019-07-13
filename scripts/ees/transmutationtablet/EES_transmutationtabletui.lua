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

  -- Initiallize window title and icon
  pane.setTitle(
    "^orange;" .. config.getParameter("eesTitle") .. "^reset;",
    "Transmutation tablet"
  )
  pane.setTitleIcon(config.getParameter("eesTitleIcon"))

  -- Initiallize player emc
  widget.setImage("iconMainEmc", "/items/EES/currency/" .. self.mainEmc .. ".png")
  updatePlayerEmcLabels()

  -- Initiallize the crafting grid
  EES_refreshAllCrafting()
end

-- Hook function called when the GUI is closed.
EES_superUninit = uninit
function uninit()
  if EES_superUninit then EES_superUninit() end

  -- Dump all the items out of the book.
  for studySlot = self.initStudySlots, self.endStudySlots do
    local slotItem = EES_getItemAtSlot(studySlot)
		if slotItem then player.giveItem(slotItem) end
  end
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

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- Updates the labels for the player EMC with the current player EMC.
function updatePlayerEmcLabels()
  widget.setText("labelMainEmc", player.currency(self.mainEmc))
  widget.setText("labelUniversalEmc", player.currency("EES_universalemc"))
end
