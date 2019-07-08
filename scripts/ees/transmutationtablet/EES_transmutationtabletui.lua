require "/scripts/ees/common/EES_transmutation_study.lua"
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
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

function swapItem(widgetName)
  local slotItem = widget.itemSlotItem(widgetName)
  local swapItem = player.swapSlotItem()

  if not swapItem or self.canStudy[swapItem.name] then
    player.setSwapSlotItem(slotItem)
    widget.setItemSlotItem(widgetName, swapItem)
  else
    pane.playSound("/sfx/interface/clickon_error.ogg")
  end
end

--------------------------------------------------------------------------------
------------------------------- Public functions -------------------------------
--------------------------------------------------------------------------------

-- Get "configName" from the config of the UI.
function EES_getConfig(configName)
  return config.getParameter(configName)
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------
