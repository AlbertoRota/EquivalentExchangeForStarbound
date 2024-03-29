require "/scripts/ees/common/EES_transmutation_study.lua"
require "/scripts/ees/EES_utils.lua"

--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the obj is created/placed in the world.
EES_superInit = init
function init()
  if EES_superInit then EES_superInit() end

  container = {}

  -- Load config from the ".object" file.
  self.initBurnSlots   = EES_getConfig("eesSlotConfig.initBurnSlots")
  self.endBurnSlots    = EES_getConfig("eesSlotConfig.endBurnSlots")

  -- Register mesagges that will be called by the GUI.
  message.setHandler("clearStudySlots", clearStudySlots)
  message.setHandler("clearBurnSlots", clearBurnSlots)
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

-- Get "configName" from the config.
-- Abstracts object/activeItem/scriptedPane diferencies.
function EES_getConfig(configName)
  return config.getParameter(configName)
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
