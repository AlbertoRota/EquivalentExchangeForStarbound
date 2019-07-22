--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_stackSuperInit = init
function init()
  if EES_stackSuperInit then EES_stackSuperInit() end

  -- Save the "canStudy" as an array, so that we can iterate it in for loops
  EES_refreshStackList()
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

-- Move the items that can be studied from the player inventory to the slots.
function buttonFromInventory()

  -- First pass, stack simmilar items and return the emppty slots
  local containerFreeSlots = stackSimilarItems()

  -- Second pass, fill free slots
  fillEmptySlots(containerFreeSlots)

  -- Re-calculate and display the "studyEmc" value
  widget.setText("labelStudyEmc", EES_calculateStudyEmcValue())
end

--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

function EES_refreshStackList()
  -- Save the "canStudy" as an array, so that we can iterate it in for loops
  self.canStudyArr = {}
  for k,v in pairs(self.canStudy) do
    table.insert(self.canStudyArr, k)
  end
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- Stacks similar items and return the emppty slots
function stackSimilarItems()
  local containerFreeSlots = {}

  for studySlot = self.initStudySlots, self.endStudySlots do
    local slotItem = EES_getItemAtSlot(studySlot)
		if slotItem then
      moveItemFromPlayerToContainerSlot(slotItem, studySlot)
		else
      table.insert(containerFreeSlots, studySlot)
    end
  end

  return containerFreeSlots
end

-- Fills the empty slots with valid items from the player's inventory
function fillEmptySlots(freeSlots)
  for _, freeSlot in pairs(freeSlots) do
    local filled = false
    local idx = 1

    while (not filled) and (idx <= #self.canStudyArr) do
      -- Try to move the item from the player inventory
      local slotItem = {name = self.canStudyArr[idx], count = 0}
      filled = moveItemFromPlayerToContainerSlot(slotItem, freeSlot)

      -- If nothing was moved, move to the next one
      if not filled then
        idx = idx + 1
      end
    end
  end
end

-- Moves the specified item from the player invnetory to the container slot.
-- Returns true if something was moved, false otherwhise
function moveItemFromPlayerToContainerSlot(itemDescriptor, containerSlot)
  local moved = false
  local amount = player.hasCountOfItem(itemDescriptor, false)
  local maxStack = EES_getItemConfig(itemDescriptor.name).maxStack
  local missing = maxStack - itemDescriptor.count

  -- Move the maximum amount possible from player to slot
  if missing > 0 and amount > 0 then
    local consume = math.min(missing, amount)
    player.consumeItem(
      {name = itemDescriptor.name, count = consume},
      false,
      false
    )
    EES_applyItemAtSlot(
      {name = itemDescriptor.name, count = itemDescriptor.count + consume},
      containerSlot
    )
    moved = true
  end

  return moved
end
