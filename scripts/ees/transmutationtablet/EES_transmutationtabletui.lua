require "/scripts/ees/EES_utils.lua"

--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_superInit = init
function init()
  if EES_superInit then EES_superInit() end

  self.currentItemGridItems = {}
  self.lastItemGridItems = {}

  self.mainEmc         = config.getParameter("eesMainEmc")
  self.canStudy        = createStudyList(config.getParameter("eesCanStudy"))
  self.initStudySlots  = config.getParameter("eesSlotConfig.initStudySlots") + 1
  self.endStudySlots   = config.getParameter("eesSlotConfig.endStudySlots") + 1
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

function swapItem(widgetName)
  local slotItem = widget.itemSlotItem(widgetName)
  local swapItem = player.swapSlotItem()

  tprint(swapItem, "swapItem")
  if not swapItem or self.canStudy[swapItem.name] then
    player.setSwapSlotItem(slotItem)
    widget.setItemSlotItem(widgetName, swapItem)
  else
    pane.playSound("/sfx/interface/clickon_error.ogg")
  end

end

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
