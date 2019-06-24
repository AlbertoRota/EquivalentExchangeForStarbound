--------------------------------------------------------------------------------
------------------------- Starbound hooks and functions ------------------------
--------------------------------------------------------------------------------

-- Hook function called when the GUI is opened.
EES_superInit = init
function init()
  if EES_superInit then EES_superInit() end
  self.upgradeMaterials = world.getObjectParameter(pane.containerEntityId(), "eesUpgradeMaterials")
  if not self.upgradeMaterials then
    widget.setVisible("btnUpgrade", false)
  elseif not playerCanUpgrade() then
    widget.setButtonEnabled("btnUpgrade", false)
  end
end

--------------------------------------------------------------------------------
-------------------------- Buttons hooks and functions -------------------------
--------------------------------------------------------------------------------

-- btnUpgrade
function btnUpgrade()
  if consumeUpgradeMaterials() then
    world.sendEntityMessage(pane.containerEntityId(), "requestUpgrade")
    pane.dismiss()
  end
end

--------------------------------------------------------------------------------
------------------------------ Private functions -------------------------------
--------------------------------------------------------------------------------

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
