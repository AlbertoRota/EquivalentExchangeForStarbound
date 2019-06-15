require "/scripts/ees/EES_utils.lua"

--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
function init()
  container = {}
  lastItemGridItems = {}
  studyEmc = 0
  burnEmc = 0

  -- Load config from the ".object" file of the linked container.
  initStudySlots  = getMandatoryConfig("eesSlotConfig.initStudySlots") + 1
  endStudySlots   = getMandatoryConfig("eesSlotConfig.endStudySlots") + 1
  initBurnSlots   = getMandatoryConfig("eesSlotConfig.initBurnSlots") + 1
  endBurnSlots    = getMandatoryConfig("eesSlotConfig.endBurnSlots") + 1

  tprint(root.itemConfig("dirtmaterial"), "dirtmaterial")
  tprint(root.itemConfig("liquidwater"), "liquidwater")
end

-- Hook function called every "scriptDelta".
function update(dt)
  -- Pool the itemGrid to check if the inventory has changed
  local itemGridItems = widget.itemGridItems("itemGrid")
  if itemListAreDifferent(itemGridItems, lastItemGridItems, initStudySlots, endBurnSlots) then
    -- Re-calculate and display the "studyEmc" value
    studyEmc = calculateItemListEmcValue(itemGridItems, initStudySlots, endStudySlots, 1)
    widget.setText("labelStudyEmc", studyEmc)

    -- Re-calculate and display the "burnEmc" value
    burnEmc = calculateItemListEmcValue(itemGridItems, initBurnSlots, endBurnSlots, 0.1)
    widget.setText("labelBurnEmc", burnEmc)

    -- Display player emc
    widget.setText("labelOreEmc", player.currency("EES_oreemc"))
    widget.setText("labelUniversalEmc", player.currency("EES_universalemc"))

    -- Update "lastItemGridItems" with the new values
    lastItemGridItems = itemGridItems
  end
end

-- Hook function called when the GUI is opened.
function uninit()
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

-- Adds the emcValue to the player currency and clears the study slots
function buttonStudy()
  traceprint("ui - buttonStudy")
  local itemGridItems = widget.itemGridItems("itemGrid")
  studyEmc = calculateItemListEmcValue(itemGridItems, initStudySlots, endStudySlots, 1)
  player.addCurrency("EES_oreemc", studyEmc)
  world.sendEntityMessage(pane.containerEntityId(), "clearStudySlots")
end

-- Adds the emcValue to the player currency and clears the burn slots
function buttonBurn()
  traceprint("ui - buttonBurn")
  local itemGridItems = widget.itemGridItems("itemGrid")
  studyEmc = calculateItemListEmcValue(itemGridItems, initBurnSlots, endBurnSlots, 0.1)
  player.addCurrency("EES_universalemc", studyEmc)
  world.sendEntityMessage(pane.containerEntityId(), "clearBurnSlots")
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- Get "configName" from the config of the source object.
-- Raises error if not found.
-- TODO: Check "getMandatoryConfig" in "EES_transmutationtableobj.lua" and merge
function getMandatoryConfig(configName)
  local errMsgMissingConfig = "Configuration parameter \"%s\" not found."
  local value = world.getObjectParameter(pane.containerEntityId(), configName)
  if not value then
    error(string.format(errMsgMissingConfig, configName))
  end
  return value
end

-- Compares two "itemList" to see if the have the same items in the same slots.
function itemListAreDifferent(itemList1, itemList2, startSlot, endSlot)
  local hasChanged = false
  for slot = startSlot, endSlot do
    -- Pick one item from each list
    local item_1 = itemList1[slot]
    local item_2 = itemList2[slot]

    if item_1 == nil and item_2 == nil then
      -- If the slot is empty in both list, skipt the rest of the validations
    elseif item_1 == nil and item_2 ~= nil then
      -- Slot is empty in the first list, but not in the second
      hasChanged = true
    elseif item_1 ~= nil and item_2 == nil then
      -- Slot is empty in the second list, but not in the first
      hasChanged = true
    elseif item_1.name ~= item_2.name then
      -- They are different items
      hasChanged = true
    elseif item_1.count ~= item_2.count then
      -- The ammount of items is different
      hasChanged = true
    end
  end

  return hasChanged
end

-- Calculates the EMC value of an "itemList"
-- TODO: Needs to be improved
function calculateItemListEmcValue(itemList, startSlot, endSlot, sellFactor)
  local emcValue = 0
  for slot = startSlot, endSlot do
    local item = itemList[slot]
    if item then
      local itemConfig = root.itemConfig(item.name)
      if itemConfig then
        local itemPrice = itemConfig.config.price
        if not itemPrice or itemPrice < 5 then itemPrice = 5 end
        emcValue = emcValue + math.floor(itemPrice * item.count * sellFactor)
      end
    end
  end
  return emcValue
end
