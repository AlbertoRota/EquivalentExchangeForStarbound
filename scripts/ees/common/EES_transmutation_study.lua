--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_studySuperInit = init
function init()
  if EES_studySuperInit then EES_studySuperInit() end

  self.canStudy        = createStudyList(EES_getConfig("eesCanStudy"))
  self.initStudySlots  = EES_getConfig("eesSlotConfig.initStudySlots") + 1
  self.endStudySlots   = EES_getConfig("eesSlotConfig.endStudySlots") + 1
end

-- Hook function called by "Upgradeable" objects.
EES_studySuperUpgradeTo = upgradeTo
function upgradeTo(oldStage, newStage)
  if EES_studySuperUpgradeTo then EES_studySuperUpgradeTo(oldStage, newStage) end
  self.canStudy = createStudyList(EES_getConfig("eesCanStudy"))
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
