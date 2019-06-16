require "/scripts/ees/EES_utils.lua"

--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the obj is created/placed in the world.
function init()
  container = {}

  -- Load config from the ".object" file.
  self.canStudy        = getMandatoryConfig("eesCanStudy")
  self.initStudySlots  = getMandatoryConfig("eesSlotConfig.initStudySlots")
  self.endStudySlots   = getMandatoryConfig("eesSlotConfig.endStudySlots")
  self.initBurnSlots   = getMandatoryConfig("eesSlotConfig.initBurnSlots")
  self.endBurnSlots    = getMandatoryConfig("eesSlotConfig.endBurnSlots")

  -- Register mesagges that will be called by the GUI.
  message.setHandler("clearStudySlots", clearStudySlots)
  message.setHandler("clearBurnSlots", clearBurnSlots)
end

-- Hook function called every "scriptDelta".
function update(dt)
end

-- Hook function called after any modification to the "itemgrid" elements.
function containerCallback()
  -- Check all the "Study" slots for invalid items
  for studySlot = self.initStudySlots, self.endStudySlots do
    local item = world.containerItemAt(entity.id(), studySlot)

    -- If the item is not in "canStudy", move it out of the "Study" slots.
    if item and not self.canStudy[item.name] then
      moveToBurnSlotOrEjectItem(studySlot)
    end
  end
end

-- Hook function called when the obj is removed from the world.
function uninit()
end

--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

-- Clears the Study slots.
-- Called by "world.sendEntityMessage(entityId, 'clearStudySlots')"
function clearStudySlots()
  for studySlot = self.initStudySlots, self.endStudySlots do
    world.containerTakeAt(entity.id(), studySlot)
  end
end

-- Clears the Burn slots.
-- Called by "world.sendEntityMessage(entityId, 'clearBurnSlots')"
function clearBurnSlots()
  for burnSlot = self.initBurnSlots, self.endBurnSlots do
    world.containerTakeAt(entity.id(), burnSlot)
  end
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

-- Get "configName" from the config, raises error if not found.
function getMandatoryConfig(configName)
  local errMsgMissingConfig = "Configuration parameter \"%s\" not found."
  local value = config.getParameter(configName)
  if not value then
    error(string.format(errMsgMissingConfig, configName))
  end
  return value
end

-- Attemps to move the item in the specified slot to one of the "Burn" slots.
-- If it's impossible to the item there, it gets ejected out of the container.
function moveToBurnSlotOrEjectItem(containerSlot)
  -- Take the item out of it's current slot.
  local itemToBeMoved = world.containerTakeAt(entity.id(), containerSlot)

  -- Try to fit the item in any of the "Burn" slots.
  for burnSlot = self.initBurnSlots, self.endBurnSlots do
    itemToBeMoved = world.containerPutItemsAt(entity.id(), itemToBeMoved, burnSlot)
  end

  -- If we were unable to fit the item in the "Burn" slots, eject it.
  if itemToBeMoved then
    world.spawnItem(itemToBeMoved, entity.position())
  end
end
