--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

-- Updates the player's transmutation book with the info of the study slots.
function EES_updateTransmutationBook()
  local updated = false
  local book = player.itemsWithTag("EES_transmutationbook")[1]
  if not book then return false end

  -- Initiallize the relevant parameters if not present.
  initBook(book)

  -- Update the info of the transmutations.
  for slot = self.initStudySlots, self.endStudySlots do
    -- Check if the slot contains a valid item
    local itemDescriptor = EES_getItemAtSlot(slot)
    if itemDescriptor then -- The slot has an item
      local idx = findOrCreateTransmutation(book, itemDescriptor.name)
      updated = updateProgress(book, idx, itemDescriptor.count) or updated
    end
  end

  if updated then
    -- If the book has been updated, give the updated version to the player.
    player.consumeTaggedItem("EES_transmutationbook", 1)
    player.giveItem(book)
  end

  return updated
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- If not present, creates all the structure tree inside "book"
function initBook(book)
  if not book.parameters.eesTransmutations then
    book.parameters.eesTransmutations = {}
  end
  if not book.parameters.eesTransmutations[self.mainEmc] then
    book.parameters.eesTransmutations[self.mainEmc] = {}
  end
end

-- Returns the index of the transmutation.
-- If not present, creates a new one and returns it's index.
function findOrCreateTransmutation(book, name)
  -- First, try to find the transmutation in the book and return it's index.
  local transmutations = book.parameters.eesTransmutations[self.mainEmc]
  for idx, transmutation in ipairs(transmutations) do
    if transmutation.name == name then return idx end
  end

  -- If not found, create a new one and return it's index.
  local itemPrice = root.itemConfig(name).config.price or 0
  if itemPrice < self.minItemPrice then itemPrice = self.minItemPrice end
  local last = #book.parameters.eesTransmutations[self.mainEmc] + 1
  book.parameters.eesTransmutations[self.mainEmc][last] = {
    known = false, progress = 0, name = name, price = itemPrice
  }
  return last
end

-- Updates the progress on the transmutation.
-- Returns true if the book has changed.
function updateProgress(book, idx, count)
  local transmutation = book.parameters.eesTransmutations[self.mainEmc][idx]
  if transmutation.known then
    -- Transmutation known, no need to update it.
    return false
  else
    -- It's an unknown item, update the transmutation information
    transmutation.progress = transmutation.progress + count
    if transmutation.progress >= 10 then
      transmutation.known = true
      transmutation.progress = 10
    end

    -- Save that information back into the book
    book.parameters.eesTransmutations[self.mainEmc][idx] = transmutation
    return true
  end
end
