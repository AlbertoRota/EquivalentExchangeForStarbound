--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_upgradeSuperInit = init
function init()
  if EES_upgradeSuperInit then EES_upgradeSuperInit() end
  self.upgradeMaterials = world.getObjectParameter(pane.containerEntityId(), "eesUpgradeMaterials")
  self.canUpgrade = playerCanUpgrade() or player.isAdmin()

  initUpgradeTooltip()
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

-- checkBoxUpgrade
function checkBoxUpgrade()
  widget.setVisible("layoutUpgrade", not widget.active("layoutUpgrade"))
end

-- btnUpgrade
function btnUpgrade()
  if consumeUpgradeMaterials() or player.isAdmin() then
    world.sendEntityMessage(pane.containerEntityId(), "requestUpgrade")
    pane.dismiss()
  end
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

function initUpgradeTooltip()
  local numItems = #self.upgradeMaterials

  -- No further upgrades, remove the button and return.
  if numItems == 0 then
    widget.setVisible("checkBoxUpgrade", false)
    return false
  end

  -- Set the correct images for "Upgrade" checkbox.
  if self.canUpgrade then
    widget.setButtonImages(
      "checkBoxUpgrade",
      {base = "/interface/ees/transmutationtable/EES_upgradeReady.png"}
    )
    widget.setButtonCheckedImages(
      "checkBoxUpgrade",
      {base = "/interface/ees/transmutationtable/EES_upgradeReadyChecked.png"}
    )
  end

  -- Enable or disable the "Upgrade" button.
  widget.setButtonEnabled("layoutUpgrade.btnUpgrade", self.canUpgrade)

  -- Update the height of the tooltip to match the contents
  local itemList = config.getParameter("gui.layoutUpgrade.children.upgradeIngredientsList.schema")
  local memberSize, spacing = itemList.memberSize, itemList.spacing
  local backgroundSize = widget.getSize("layoutUpgrade.background")
  local listHeight = numItems * (memberSize[2] + spacing[2]) - spacing[2]
  widget.setSize(
    "layoutUpgrade",
    {backgroundSize[1], backgroundSize[2] + listHeight}
  )
  widget.setSize(
    "layoutUpgrade.background",
    {backgroundSize[1], backgroundSize[2] + listHeight}
  )

  -- Update the position of the tooltip to match the contents
  local layoutPos = widget.getPosition("layoutUpgrade")
  widget.setPosition(
    "layoutUpgrade",
    {layoutPos[1], layoutPos[2] - listHeight}
  )

  -- Update the position of the title to remain on the top
  local titlePosition = widget.getPosition("layoutUpgrade.title")
  widget.setPosition(
    "layoutUpgrade.title",
    {titlePosition[1], titlePosition[2] + listHeight}
  )

  -- Add all items to the list.
  local ingredientsList = "layoutUpgrade.upgradeIngredientsList"
  widget.clearListItems(ingredientsList)
  for _, upgradeMaterial in pairs(self.upgradeMaterials) do
    local itemName, count = upgradeMaterial.item, upgradeMaterial.count
    local itemConfig = root.itemConfig(itemName).config
    local newItem = string.format(
      "%s.%s",
      ingredientsList,
      widget.addListItem(ingredientsList)
    )

    -- Basic info.
    widget.setText(newItem..".itemName", itemConfig.shortdescription)
    widget.setItemSlotItem(
      newItem..".itemIcon",
      { name = itemName, count = 1 }
    )
    widget.setText(
      newItem..".count",
      player.hasCountOfItem(itemName).."/"..count
    )
  end
end

function playerCanUpgrade()
  if not self.upgradeMaterials then return false end

  local playerHasMaterials = true
  for _, material in pairs(self.upgradeMaterials) do
    playerHasMaterials = playerHasMaterials and player.hasCountOfItem({name = material.item}) >= material.count
  end

  return playerHasMaterials
end

function consumeUpgradeMaterials()
  if not self.upgradeMaterials then return false end

  local materialsConsumed = true
  for _, material in pairs(self.upgradeMaterials) do
    materialsConsumed = materialsConsumed and player.consumeItem({name = material.item, count = material.count})
  end

  return materialsConsumed
end
