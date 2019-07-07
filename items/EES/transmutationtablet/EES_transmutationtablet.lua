function activate(fireMode, shiftHeld)
    activeItem.interact(
      "ScriptPane",
      "/interface/ees/transmutationtablet/EES_transmutationtablet.config"
    )
    animator.playSound("activate")
end


function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end
