function activate(fireMode, shiftHeld)
  -- Load the basic UI config
  local configData = root.assetJson("/interface/ees/transmutationtablet/EES_transmutationtablet.config")

  -- Pass the object specific config to the UI
  configData.eesMainEmc = config.getParameter("eesMainEmc")
  configData.eesSlotConfig = config.getParameter("eesSlotConfig")
  configData.eesCanStudy = config.getParameter("eesCanStudy")
  configData.eesTitle = config.getParameter("shortdescription")
  configData.eesTitleIcon = config.getParameter("inventoryIcon")

  -- Open the UI
  activeItem.interact("ScriptPane", configData)
  animator.playSound("activate")
end


function update()
  if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end
