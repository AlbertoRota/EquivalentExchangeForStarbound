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
  self.itemList = "scrollArea.itemList"

  -- Load config from the ".object" file of the linked container.
  initStudySlots  = getMandatoryConfig("eesSlotConfig.initStudySlots") + 1
  endStudySlots   = getMandatoryConfig("eesSlotConfig.endStudySlots") + 1
  initBurnSlots   = getMandatoryConfig("eesSlotConfig.initBurnSlots") + 1
  endBurnSlots    = getMandatoryConfig("eesSlotConfig.endBurnSlots") + 1

  -- Add a dummy item to the transmutationBook.
  -- TODO: Delete this
  initTransmutationBook()

  -- Initiallize the itemList
  populateItemList()

  -- Initiallize player emc
  updatePlayerEmcLabels()
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
    updatePlayerEmcLabels()

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

-- Gets one unit of the item selected in the list.
function buttonGetOne()
  craftSelectedWithEmc(1)
end

-- Gets five unit of the item selected in the list.
function buttonGetFive()
  craftSelectedWithEmc(5)
end

-- Gets ten unit of the item selected in the list.
function buttonGetTen()
  craftSelectedWithEmc(10)
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

-- Updates the labels for the player EMC with the current player EMC.
function updatePlayerEmcLabels()
  widget.setText("labelOreEmc", player.currency("EES_oreemc"))
  widget.setText("labelUniversalEmc", player.currency("EES_universalemc"))
end

-- Debug function to pre-load a "EES_transmutationbook" for the player.
-- TODO: Delete this
function initTransmutationBook()
  local transmutationBook = { name = "EES_transmutationbook", count = 1 }
  local itemDes = player.consumeItem(transmutationBook, false, false)

  if not itemDes.parameters.eesTransmutations then
    itemDes.parameters.eesTransmutations = {}
  end
  if not itemDes.parameters.eesTransmutations["ore"] then
    itemDes.parameters.eesTransmutations["ore"] = {}
  end

  local coalore = { known = true, new = false, progress = 10, price = 2, name = "coalore" }
  itemDes.parameters.eesTransmutations.ore[0] = coalore
  local ironore = { known = true, new = true, progress = 10 , price = 20, name = "ironore" }
  itemDes.parameters.eesTransmutations.ore[1] = ironore
  local copperore = { known = false, new = false, progress = 4, price = 10, name = "copperore" }
  itemDes.parameters.eesTransmutations.ore[2] = copperore

  player.giveItem(itemDes)
end

function populateItemList()
  -- Check if the player has an "EES_transmutationbook".
  local transmutationBook = player.itemsWithTag("EES_transmutationbook")[1]

  -- Get and sort all player known transmutations from the book.
  local transmutationList = transmutationBook.parameters.eesTransmutations["ore"]
  table.sort(
    transmutationList,
    function(a, b)
      if a.price ~= b.price then
        return a.price < b.price
      else
        return string.lower(a.name) < string.lower(b.name)
      end
    end
  )

  -- Add all known transmutations to the list.
  widget.clearListItems(self.itemList)
  for _, transmutation in pairs(transmutationList) do
    local itemConfig = root.itemConfig(transmutation.name).config
    local newItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))

    -- Basic info.
    widget.setText(newItem..".itemName", itemConfig.shortdescription)
    widget.setText(newItem..".priceLabel", itemConfig.price)
    widget.setItemSlotItem(
      newItem..".itemIcon",
      { name = itemConfig.itemName, count = 1 }
    )

    -- Toggle element visibility.
    widget.setVisible(newItem..".newIcon", transmutation.new)
    widget.setVisible(newItem..".notcraftableoverlay", not transmutation.known)

    -- Store the "transmutation" as "data", so that it can be used later.
    widget.setData(newItem, transmutation)
  end
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

function craftSelectedWithEmc(count)
  -- Get the currently selected item.
  local selectedListItem = widget.getListSelected(self.itemList)
  if selectedListItem then
    local itemData = widget.getData(
      string.format("%s.%s", self.itemList, selectedListItem)
    )

    local totalPrice = itemData.price * count
    local playerOreEmc = player.currency("EES_oreemc")
    local playerUniversalEmc = player.currency("EES_universalemc")

    if totalPrice <= playerOreEmc then
      player.consumeCurrency("EES_oreemc", totalPrice)
      -- Give the player the desired ammount of items.
      player.giveItem({name = itemData.name, count = count})
    elseif totalPrice - playerOreEmc <= playerUniversalEmc then
      player.consumeCurrency("EES_oreemc", playerOreEmc)
      player.consumeCurrency("EES_universalemc", totalPrice - playerOreEmc)
      -- Give the player the desired ammount of items.
      player.giveItem({name = itemData.name, count = count})
    end

    -- Display player emc
    updatePlayerEmcLabels()
  end
end
