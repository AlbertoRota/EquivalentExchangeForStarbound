--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_searchSuperInit = init
function init()
  if EES_searchSuperInit then EES_searchSuperInit() end
  self.searchFilter = ""
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

-- searchCallback
function searchCallback()
  local newSearchText = widget.getText("searchField")
  newSearchText = string.lower(newSearchText)

  if self.searchFilter ~= newSearchText then
    self.searchFilter = newSearchText
    traceprint("Populating list - " .. self.searchFilter)
    populateItemList()
  end
end

-- searchEnter
function searchEnter()
  widget.blur("searchField")
end

-- searchAbort
function searchAbort()
  widget.setText("searchField", "")
  widget.blur("searchField")
end

--------------------------------------------------------------------------------
------------------------------ Public functions -------------------------------
--------------------------------------------------------------------------------
function EES_itemMatchFilter(itemConfig)
  -- Check "shortdescription"
  if stringMatchFilter(itemConfig.shortdescription) then return true end

  -- Check "description"
  -- if stringMatchFilter(itemConfig.description) then return true end

  -- No match, return false
  return false
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------
function stringMatchFilter(text)
  return string.find(string.lower(text or ""), self.searchFilter or "")
end
