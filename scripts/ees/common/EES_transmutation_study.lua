require "/scripts/ees/common/EES_transmutation_bookupdate.lua"

--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_studySuperInit = init
function init()
  if EES_studySuperInit then EES_studySuperInit() end

  self.canStudy        = createStudyList(EES_getConfig("eesCanStudy"))
  self.initStudySlots  = EES_getConfig("eesSlotConfig.initStudySlots")
  self.endStudySlots   = EES_getConfig("eesSlotConfig.endStudySlots")
end

-- Hook function called by "Upgradeable" objects.
EES_studySuperUpgradeTo = upgradeTo
function upgradeTo(oldStage, newStage)
  if EES_studySuperUpgradeTo then EES_studySuperUpgradeTo(oldStage, newStage) end
  self.canStudy = createStudyList(EES_getConfig("eesCanStudy"))
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

-- Adds the emcValue to the player currency and clears the study slots
function buttonStudy()
  -- Add the EMC and update the Book
  player.addCurrency(self.mainEmc, EES_calculateStudyEmcValue())
  local bookUpdated = EES_updateTransmutationBook()

  -- Clear the  slots and update the buy buttons
  for slot = self.initStudySlots, self.endStudySlots do
    EES_setItemAtSlot(nil, slot)
  end

  -- Update all the depending fields
  widget.setText("labelMainEmc", player.currency(self.mainEmc))
  widget.setText("labelStudyEmc", EES_calculateStudyEmcValue())
  if EES_refreshAllCrafting then EES_refreshAllCrafting() end
end

--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

function createStudyList(studyConfig)
  local out = {}
  local studyListConfig = root.assetJson("/EES_transmutationstudylist.config")

  for emcType, tiers in pairs(studyConfig) do
    for i, tier in ipairs(tiers) do
      local tierConfig = studyListConfig[emcType][tier]
      for k,v in pairs(tierConfig) do out[k] = v end
    end
  end

  return out
end
