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
  -- Filter out erroneous items
  if itemConfig.error then return false end

  -- Filter out items that can't be studyed
  if not itemConfig.isStudyable then return false end

  -- Check "shortdescription"
  if stringMatchFilter(itemConfig.shortdescription) then return true end

  -- No match, return false
  return false
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------
function stringMatchFilter(text)
  return string.find(string.lower(text or ""), self.searchFilter or "")
end
