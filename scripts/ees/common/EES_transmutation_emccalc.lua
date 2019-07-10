--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_emccalcSuperInit = init
function init()
  if EES_emccalcSuperInit then EES_emccalcSuperInit() end

  self.minItemPrice = 1
end
--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

-- Calculates the EMC value of all the items in the "Study" slots.
function EES_calculateStudyEmcValue()
  return EES_calculateSlotsEmcValue(self.initStudySlots, self.endStudySlots, 1)
end

-- Calculates the EMC value of all the items in the "Burn" slots.
function EES_calculateBurnEmcValue()
  return EES_calculateSlotsEmcValue(self.initBurnSlots, self.endBurnSlots, 0.1)
end

-- Calculates the EMC value of the items in slots between "initSlot" and "endSlot".
function EES_calculateSlotsEmcValue(initSlot, endSlot, factor)
  local emcValue = 0
  for slot = initSlot, endSlot do
    emcValue = emcValue + EES_calculateItemEmcValue(EES_getItemAtSlot(slot), factor)
  end
  return emcValue
end

-- Calculates the EMC value of the given item.
function EES_calculateItemEmcValue(item, factor)
  -- In no item is passed, return 0
  if not item then return 0 end

  -- Obtain the relevant information of the item
  local itemPrice = root.itemConfig(item.name).config.price or 0

  -- Obtain the value of a single item
  if itemPrice < self.minItemPrice then itemPrice = self.minItemPrice end

  -- Calculate the value of all the items in the "item"
  return math.floor(itemPrice * item.count * factor)
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------
