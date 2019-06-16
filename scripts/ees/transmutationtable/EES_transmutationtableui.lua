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
  updateTransmutationBook()
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

-- Updates the player's transmutation book with the info of the study slots.
-- TODO: Seriously rethink and refactor this code. (Too long and complex)
function updateTransmutationBook()
  local transmutationBookUpdated = false
  local transmutationBook = player.itemsWithTag("EES_transmutationbook")[1]

  -- Initiallize the relevant parameters if not present.
  if not transmutationBook.parameters.eesTransmutations then
    transmutationBook.parameters.eesTransmutations = {}
    transmutationBookUpdated = true
  end
  if not transmutationBook.parameters.eesTransmutations["ore"] then
    transmutationBook.parameters.eesTransmutations["ore"] = {}
    transmutationBookUpdated = true
  end

  -- Update the info of the transmutations.
  local itemList = widget.itemGridItems("itemGrid")
  for slot = initStudySlots, endStudySlots do
    -- Check if the slot contains a valid item
    local item = itemList[slot]
    if item then -- The slot has an item
      local itemConfig = root.itemConfig(item.name)
      if itemConfig then -- The item is valid

        local itemTransmutation = transmutationBook.parameters.eesTransmutations["ore"][item.name]
        if not itemTransmutation then
          -- It's a new item, initiallize it and add it to the book
          local newItemTransmutation = {
            known = false,
            new = false,
            progress = item.count,
            price = itemConfig.config.price or 1,
            name = item.name
          }
          if newItemTransmutation.progress >= 10 then
            newItemTransmutation.known = true
            newItemTransmutation.new = true
            newItemTransmutation.progress = 10
          end
          transmutationBook.parameters.eesTransmutations["ore"][item.name] = newItemTransmutation
          transmutationBookUpdated = true
        elseif not itemTransmutation.known then
          -- It's an unknown item, update book information
          itemTransmutation.progress = itemTransmutation.progress + item.count
          if itemTransmutation.progress >= 10 then
            itemTransmutation.known = true
            itemTransmutation.new = true
            itemTransmutation.progress = 10
          end
          transmutationBookUpdated = true
        end
      end
    end
  end

  -- If the book has been updated, give the updated version to the player.
  if transmutationBookUpdated then
    player.consumeTaggedItem("EES_transmutationbook", 1)
    player.giveItem(transmutationBook)

    -- Re-populate the list to refresh the changes
    populateItemList()
  end
end

-- Updates the ui with the info of the player's transmutation book.
-- TODO: Seriously rethink and refactor this code. (Too long and complex)
function populateItemList()
  -- Check if the player has an "EES_transmutationbook".
  local transmutationBook = player.itemsWithTag("EES_transmutationbook")[1]
  if not transmutationBook or not transmutationBook.parameters.eesTransmutations or not transmutationBook.parameters.eesTransmutations["ore"] then
    return
  end
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
-- TODO: Needs to be improved to allow more complex calculations.
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

-- Gives the player the item slected in the itemList.
-- Consumes EMC in the process, first the specific, then the universal.
-- TODO: Seriously rethink and refactor this code.
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
