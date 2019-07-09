require "/scripts/ees/common/EES_transmutation_study.lua"
require "/scripts/ees/EES_utils.lua"

--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_superInit = init
function init()
  if EES_superInit then EES_superInit() end

  self.currentItemGridItems = {}
  self.lastItemGridItems = {}

  self.mainEmc         = config.getParameter("eesMainEmc")
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
        applyItemToSlot(swapItem, string.sub(widgetName, -1))
      )
    end
  else
    pane.playSound("/sfx/interface/clickon_error.ogg")
  end
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

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- Add the specified items to the given slot, returning the leftover.
function applyItemToSlot(itemToAdd, slot)
  local slotItem = EES_getItemAtSlot(slot)

  if not slotItem then
    -- Slot is empty, move all the items and return.
    EES_setItemAtSlot(itemToAdd, slot)
    return nil
  elseif itemToAdd.name ~= slotItem.name then
    -- Only items of the same type can be stacked, do nothing.
    return itemToAdd
  else
    -- Calculate how many items we can add.
    local slotItemConfig = root.itemConfig(slotItem).config
    local maxStack = (slotItemConfig.category and slotItemConfig.category == "Blueprint" and 1) or slotItemConfig.maxStack or root.assetJson("/items/defaultParameters.config:defaultMaxStack")
    local missing = maxStack - slotItem.count
    local amountToAdd = math.min(missing, itemToAdd.count)

    -- Add the amount to the slot.
    slotItem.count = slotItem.count + amountToAdd
    EES_setItemAtSlot(slotItem, slot)

    -- Return the items we were unable to fit.
    itemToAdd.count = itemToAdd.count - amountToAdd
    return itemToAdd.count ~= 0 and itemToAdd or nil
  end
end
