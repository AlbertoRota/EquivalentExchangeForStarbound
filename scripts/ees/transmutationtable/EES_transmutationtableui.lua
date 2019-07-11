require "/scripts/ees/common/EES_transmutation_study.lua"
require "/scripts/ees/common/EES_transmutation_craft.lua"
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
  container = {}
  self.lastItemGridItems = {}
  self.defaultMaxStack = root.assetJson("/items/defaultParameters.config:defaultMaxStack")
  self.canUse = #player.itemsWithTag("EES_transmutationbook") == 1

  -- Load config from the ".object" file of the linked container.
  self.mainEmc         = EES_getConfig("eesMainEmc")
  self.initBurnSlots   = EES_getConfig("eesSlotConfig.initBurnSlots")
  self.endBurnSlots    = EES_getConfig("eesSlotConfig.endBurnSlots")

  if self.canUse then
    -- Initiallize player emc
    widget.setImage("iconMainEmc", "/items/EES/currency/" .. self.mainEmc .. ".png")
    updatePlayerEmcLabels()

    -- Initiallize the crafting grid
    EES_refreshAllCrafting()

    widget.setVisible("imgDisabledOverlay", false)
    widget.setVisible("labelDisabledOverlay", false)
  end
end

-- Hook function called every "scriptDelta".
EES_superUpdate = update
function update(dt)
  if EES_superUpdate then EES_superUpdate() end
  -- Pool the itemGrid to check if the inventory has changed
  if itemGridHasChanged() then
    -- Re-calculate and display the "studyEmc" value
    widget.setText("labelStudyEmc", EES_calculateStudyEmcValue())

    -- Re-calculate and display the "burnEmc" value
    widget.setText("labelBurnEmc", EES_calculateBurnEmcValue())

    -- Display player emc
    updatePlayerEmcLabels()
  end
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

-- Adds the emcValue to the player currency and clears the burn slots
function buttonBurn()
  -- Add the EMC, no need to update the Book
  player.addCurrency("EES_universalemc", EES_calculateBurnEmcValue())

  -- Clear the  slots and update the buy buttons
  world.sendEntityMessage(pane.containerEntityId(), "clearBurnSlots")
  updateBuyButtons()
end

--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

-- Get "configName" from the config.
-- Abstracts object/activeItem/scriptedpane diferencies.
function EES_getConfig(configName)
  return world.getObjectParameter(pane.containerEntityId(), configName)
end

-- Gets the item in the specified slot.
-- Abstracts container/itemGrid/itemSlot diferencies.
function EES_getItemAtSlot(slot)
  return world.containerItemAt(pane.containerEntityId(), slot)
end

-- Sets the item in the specified slot.
-- Abstracts container/itemGrid/itemSlot diferencies.
function EES_setItemAtSlot(item, slot)
   world.containerSwapItemsNoCombine(pane.containerEntityId(), item, slot)
end

-- Add the specified items to the given slot, returning the leftover.
-- Abstracts container/itemGrid/itemSlot diferencies.
function EES_applyItemAtSlot(itemToApply, slot)
  return world.containerItemApply(pane.containerEntityId(), itemToApply, slot)
end
--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- Updates the labels for the player EMC with the current player EMC.
function updatePlayerEmcLabels()
  widget.setText("labelMainEmc", player.currency(self.mainEmc))
  widget.setText("labelUniversalEmc", player.currency("EES_universalemc"))
end

-- Checks if the "itemGrid" has changed since the last check.
function itemGridHasChanged()
  local hasChanged = false

  -- Check if there are differences.
  for slot = self.initStudySlots, self.endBurnSlots do
    -- Pick one item from each list
    local currentItem = EES_getItemAtSlot(slot)
    local lastItem = self.lastItemGridItems[slot]

    if currentItem == nil and lastItem == nil then
      -- If the slot is empty in both, skipt the rest of the validations.
    elseif currentItem == nil and lastItem ~= nil then
      -- Slot is empty now, but it wasn't.
      hasChanged = true
    elseif currentItem ~= nil and lastItem == nil then
      -- Slot is filled now, but it wasn't.
      hasChanged = true
    elseif currentItem.name ~= lastItem.name then
      -- They are different items
      hasChanged = true
    elseif currentItem.count ~= lastItem.count then
      -- The ammount of items is different
      hasChanged = true
    end

    -- Update "lastItemGridItems".
    self.lastItemGridItems[slot] = currentItem
  end

  return hasChanged
end
