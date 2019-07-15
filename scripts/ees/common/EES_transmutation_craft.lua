--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_craftSuperInit = init
function init()
  if EES_craftSuperInit then EES_craftSuperInit() end

  self.itemList = "scrollArea.itemList"
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

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

-- Update the buy buttons
function listSelectedChanged()
  updateBuyButtons()
end

--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

function EES_refreshAllCrafting()
  populateItemList()
  updateBuyButtons()
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- Updates the ui with the info of the player's known transmutations.
function populateItemList()
  -- Check if the player knowns some transmutations.
  local playerTransmutations = player.getProperty("eesTransmutations")
  if not playerTransmutations or not playerTransmutations[self.mainEmc] then
    return
  end

  -- Sort all player known transmutations.
  local transmutationList = playerTransmutations[self.mainEmc]
  local orderedTransmutationList = {}
  for k, v in pairs(transmutationList) do
    table.insert(orderedTransmutationList, v)
  end
  table.sort(
    orderedTransmutationList,
    function(a, b)
      if a.price ~= b.price then
        return a.price > b.price
      else
        return a.name < b.name
      end
    end
  )

  -- Add all known transmutations to the list.
  widget.clearListItems(self.itemList)
  for _, transmutation in pairs(orderedTransmutationList) do
    local itemConfig = root.itemConfig(transmutation.name).config

    -- Skip the items that do not match the searchFilter
    if not EES_itemMatchFilter or EES_itemMatchFilter(itemConfig) then
      local newItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))

      -- Basic info.
      widget.setText(newItem..".itemName", itemConfig.shortdescription)
      widget.setText(newItem..".priceLabel", transmutation.price)
      widget.setItemSlotItem(
        newItem..".itemIcon",
        { name = itemConfig.itemName, count = 1 }
      )

      -- Toggle element visibility
      widget.setVisible(newItem..".notcraftableoverlay", not transmutation.known)
      widget.setVisible(newItem..".strudyMoreLabel", not transmutation.known)
      widget.setVisible(newItem..".strudyMoreImage", not transmutation.known)
      widget.setText(newItem..".strudyMoreLabel", transmutation.progress .. "/10")

      -- Store the "transmutation" as "data", so that it can be used later.
      widget.setData(newItem, transmutation)
    end
  end
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
      for i=1,count do
        player.giveItem({name = itemData.name, count = 1})
      end
    else
      -- TODO: Play error sound.
    end

    -- Display player emc
    EES_updatePlayerEmcLabels()

    -- Update buttons
    updateBuyButtons()
  end
end

-- Similar to "player.consumeCurrency", but for EMC.
-- Consumes first "mainEmc", using only "universalemc" if "ammount > mainEmc".
function consumePlayerEmc(ammount)
  local playerMainEmc = player.currency(self.mainEmc)
  local playerUniversalEmc = player.currency("EES_universalemc")

  if ammount <= playerMainEmc then
    -- Enough EMC of the main type, consume it first.
    player.consumeCurrency(self.mainEmc, ammount)
    return true
  elseif ammount - playerMainEmc <= playerUniversalEmc then
    -- Consume all main EMC first, the use the universal.
    player.consumeCurrency(self.mainEmc, playerMainEmc)
    player.consumeCurrency("EES_universalemc", ammount - playerMainEmc)
    return true
  else
    -- Not enough EMC to consume, return error.
    return false
  end
end

-- Enables or disables the buy buttons depending on the selected item.
function updateBuyButtons()
  -- Get the currently selected item.
  local transmutation = widget.getListSelected(self.itemList)
  if transmutation then
    local playerTotalEmc = player.currency(self.mainEmc) + player.currency("EES_universalemc")
    local itemData = widget.getData(string.format("%s.%s", self.itemList, transmutation))
    local itemPrice, itemKnown = itemData.price, itemData.known
    widget.setButtonEnabled(
      "buttonGetOne",
      itemKnown and playerTotalEmc > (itemPrice * 1)
    )
    widget.setButtonEnabled(
      "buttonGetFive",
      itemKnown and playerTotalEmc > (itemPrice * 5)
    )
    widget.setButtonEnabled(
      "buttonGetTen",
      itemKnown and playerTotalEmc > (itemPrice * 10)
    )
  else
    widget.setButtonEnabled("buttonGetOne", false)
    widget.setButtonEnabled("buttonGetFive", false)
    widget.setButtonEnabled("buttonGetTen", false)
  end
end
