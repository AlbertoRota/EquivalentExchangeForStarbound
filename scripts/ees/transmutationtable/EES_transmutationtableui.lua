require "/scripts/ees/EES_utils.lua"

--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
function init()
  container = {}
  self.currentItemGridItems = {}
  self.lastItemGridItems = {}
  self.itemList = "scrollArea.itemList"

  -- Load config from the ".object" file of the linked container.
  self.mainEmc = getMandatoryConfig("eesMainEmc")
  self.initStudySlots  = getMandatoryConfig("eesSlotConfig.initStudySlots") + 1
  self.endStudySlots   = getMandatoryConfig("eesSlotConfig.endStudySlots") + 1
  self.initBurnSlots   = getMandatoryConfig("eesSlotConfig.initBurnSlots") + 1
  self.endBurnSlots    = getMandatoryConfig("eesSlotConfig.endBurnSlots") + 1

  -- Initiallize the itemList
  populateItemList()

  -- Initiallize player emc
  updatePlayerEmcLabels()
end

-- Hook function called every "scriptDelta".
function update(dt)
  -- Pool the itemGrid to check if the inventory has changed
  if itemGridHasChanged() then
    -- Re-calculate and display the "studyEmc" value
    widget.setText("labelStudyEmc", calculateStudyEmcValue())

    -- Re-calculate and display the "burnEmc" value
    widget.setText("labelBurnEmc", calculateBurnEmcValue())

    -- Display player emc
    updatePlayerEmcLabels()
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
  -- Ensure that we are using the latest grid status
  self.currentItemGridItems = widget.itemGridItems("itemGrid")

  -- Add the EMC and update the Book
  player.addCurrency(self.mainEmc, calculateStudyEmcValue())
  updateTransmutationBook()

  -- Clear the  slots
  world.sendEntityMessage(pane.containerEntityId(), "clearStudySlots")
end

-- Adds the emcValue to the player currency and clears the burn slots
function buttonBurn()
  -- Ensure that we are using the latest grid status
  self.currentItemGridItems = widget.itemGridItems("itemGrid")

  -- Add the EMC, no need to update the Book
  player.addCurrency("EES_universalemc", calculateBurnEmcValue())

  -- Clear the  slots
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
  widget.setText("labelOreEmc", player.currency(self.mainEmc))
  widget.setText("labelUniversalEmc", player.currency("EES_universalemc"))
end

-- Updates the player's transmutation book with the info of the study slots.
function updateTransmutationBook()
  local updated = false
  local book = player.itemsWithTag("EES_transmutationbook")[1]

  -- Initiallize the relevant parameters if not present.
  initBook(book)

  -- Update the info of the transmutations.
  for slot = self.initStudySlots, self.endStudySlots do
    -- Check if the slot contains a valid item
    local itemDescriptor = self.currentItemGridItems[slot]
    if itemDescriptor then -- The slot has an item
      local idx = findOrCreateTransmutation(book, itemDescriptor.name)
      updated = updateProgress(book, idx, itemDescriptor.count) or updated
    end
  end

  if updated then
    -- If the book has been updated, give the updated version to the player.
    player.consumeTaggedItem("EES_transmutationbook", 1)
    player.giveItem(book)

    -- Re-populate the list to refresh the changes
    populateItemList()
  end
end

-- If not present, creates all the structure tree inside "book"
function initBook(book)
  if not book.parameters.eesTransmutations then
    book.parameters.eesTransmutations = {}
  end
  if not book.parameters.eesTransmutations["ore"] then
    book.parameters.eesTransmutations["ore"] = {}
  end
end

-- Returns the index of the transmutation.
-- If not present, creates a new one and returns it's index.
function findOrCreateTransmutation(book, name)
  -- First, try to find the transmutation in the book and return it's index.
  local transmutations = book.parameters.eesTransmutations["ore"]
  for idx, transmutation in ipairs(transmutations) do
    if transmutation.name == name then return idx end
  end

  -- If not found, create a new one and return it's index.
  local last = #book.parameters.eesTransmutations["ore"] + 1
  book.parameters.eesTransmutations["ore"][last] = {
    known = false, new = false, progress = 0, name = name,
    price = root.itemConfig(name).config.price or 5
  }
  return last
end

-- Updates the progress on the transmutation.
-- Returns true if the book has changed.
function updateProgress(book, idx, count)
  local transmutation = book.parameters.eesTransmutations["ore"][idx]
  if transmutation.known then
    -- Transmutation known, no need to update it.
    return false
  else
    -- It's an unknown item, update the transmutation information
    transmutation.progress = transmutation.progress + count
    if transmutation.progress >= 10 then
      transmutation.known = true
      transmutation.new = true
      transmutation.progress = 10
    end

    -- Save that information back into the book
    book.parameters.eesTransmutations["ore"][idx] = transmutation
    return true
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
        return a.price > b.price
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

-- Checks if the "itemGrid" has changed since the last check.
function itemGridHasChanged()
  local hasChanged = false

  -- Update "currentItemGridItems".
  self.currentItemGridItems = widget.itemGridItems("itemGrid")

  -- Check if there are differences.
  for slot = self.initStudySlots, self.endBurnSlots do
    -- Pick one item from each list
    local currentItem = self.currentItemGridItems[slot]
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
  end

  -- Update "lastItemGridItems".
  self.lastItemGridItems = self.currentItemGridItems
  return hasChanged
end

-- Calculates the EMC value of all the items in the "Study" slots.
function calculateStudyEmcValue()
  local emcValue = 0
  for slot = self.initStudySlots, self.endStudySlots do
    emcValue = emcValue + calculateItemEmc(self.currentItemGridItems[slot], 1)
  end
  return emcValue
end

-- Calculates the EMC value of all the items in the "Burn" slots.
function calculateBurnEmcValue()
  local emcValue = 0
  for slot = self.initBurnSlots, self.endBurnSlots do
    emcValue = emcValue + calculateItemEmc(self.currentItemGridItems[slot], 0.1)
  end
  return emcValue
end

-- Calculates the EMC value of the given "itemDescriptor".
-- "discountFactor" is 1 by default (EMC = pixel price)
function calculateItemEmc(itemDescriptor , discountFactor)
  -- Preconditions and default values
  if not itemDescriptor then return 0 end
  discountFactor = discountFactor or 1

  -- Obtain the relevant information of the item
  local itemConfig = root.itemConfig(itemDescriptor.name).config
  local itemPrice = itemConfig.price
  local itemCategory = itemConfig.category -- TODO: Will be used in the future.

  -- Obtain the value of a single item
  -- TODO: Improve the EMC calculation (Water should be worthless)
  if not itemPrice or itemPrice < 5 then itemPrice = 5 end

  -- Calculate the value of all the items in the "itemDescriptor"
  return math.floor(itemPrice * itemDescriptor.count * discountFactor)
end

-- Gives the player the item slected in the itemList.
-- Consumes EMC in the process, first the specific, then the universal.
function craftSelectedWithEmc(count)
  -- Get the currently selected item.
  local selectedListItem = widget.getListSelected(self.itemList)
  if selectedListItem then
    local itemData = widget.getData(
      string.format("%s.%s", self.itemList, selectedListItem)
    )

    local totalPrice = itemData.price * count
    if consumePlayerEmc(totalPrice) then
      player.giveItem({name = itemData.name, count = count})
    else
      -- TODO: Play error sound.
    end

    -- Display player emc
    updatePlayerEmcLabels()
  end
end

-- Similar to "player.consumeCurrency", but for EMC.
-- Consumes first "mainEmc", using only "universalemc" if "ammount > mainEmc".
function consumePlayerEmc(ammount)
  local playerOreEmc = player.currency(self.mainEmc)
  local playerUniversalEmc = player.currency("EES_universalemc")

  if ammount <= playerOreEmc then
    -- Enough EMC of the main type, consume it first.
    player.consumeCurrency(self.mainEmc, ammount)
    return true
  elseif ammount - playerOreEmc <= playerUniversalEmc then
    -- Consume all main EMC first, the use the universal.
    player.consumeCurrency(self.mainEmc, playerOreEmc)
    player.consumeCurrency("EES_universalemc", ammount - playerOreEmc)
    return true
  else
    -- Not enough EMC to consume, return error.
    return false
  end
end
