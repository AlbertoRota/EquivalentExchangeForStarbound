--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_bookupdateSuperInit = init
function init()
  if EES_bookupdateSuperInit then EES_bookupdateSuperInit() end

  -- UPDATE FROM BOOK TO PLAYER - INIT
  if player then
    local books = player.itemsWithTag("EES_transmutationbook")
    if books and books[1] then
      local playerTransmutations = {}
      local bookTransmutations = books[1].parameters.eesTransmutations or {}
      for emc, transmutations in pairs(bookTransmutations) do
        playerTransmutations[emc] = {}
        for idx, transmutation in pairs(transmutations) do
          playerTransmutations[emc][transmutation.name] = transmutation
        end
      end
      player.setProperty("eesTransmutations", playerTransmutations)
    end
  end
  -- UPDATE FROM BOOK TO PLAYER - END
end

--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

-- Updates the player's transmutation book with the info of the study slots.
function EES_updateTransmutationBook()
  -- Initiallize the relevant parameters if not present.
  initPlayer()

  -- Update the info of the transmutations.
  for slot = self.initStudySlots, self.endStudySlots do
    local itemDescriptor = EES_getItemAtSlot(slot)
    if itemDescriptor then updateProgress(itemDescriptor) end
  end
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- If not present, creates all the structure tree inside "book"
function initPlayer()
  local playerTransmutations = player.getProperty("eesTransmutations", {})
  if not playerTransmutations then playerTransmutations = {} end
  if not playerTransmutations[self.mainEmc] then
    playerTransmutations[self.mainEmc] = {}
    player.setProperty("eesTransmutations", playerTransmutations)
  end
end

-- Updates the progress on the transmutation.
-- Returns true if something was updated.
function updateProgress(item)
  local playerTransmutations = player.getProperty("eesTransmutations")

  -- If totally unknown, initiallize it.
  if not playerTransmutations[self.mainEmc][item.name] then
    local itemPrice = root.itemConfig(item.name).config.price or 0
    if itemPrice < self.minItemPrice then itemPrice = self.minItemPrice end
    playerTransmutations[self.mainEmc][item.name] = {
      known = false, progress = 0, name = item.name, price = itemPrice
    }
  end

  -- If not fully known, update the transmutation information.
  local transmutation = playerTransmutations[self.mainEmc][item.name]
  if not transmutation.known then
    transmutation.progress = transmutation.progress + item.count
    if transmutation.progress >= 10 then
      transmutation.known = true
      transmutation.progress = 10
    end

    -- Save the information back into the player
    playerTransmutations[self.mainEmc][item.name] = transmutation
    player.setProperty("eesTransmutations", playerTransmutations)
  end
end
