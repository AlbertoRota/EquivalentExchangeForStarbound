function buildGatherEmcCondition(config)
  --Set up the monster kill condition
  local gatherEmcCondition = {
    description = config.description,
    mainEmc = config.mainEmc,
    count = config.count or 1
  }

  --Set up the function for checking if the conditions were met
  function gatherEmcCondition:conditionMet()
    return player.currency(self.mainEmc) >= self.count
  end

  --Set up the function for performing actions upon quest complete
  function gatherEmcCondition:onQuestComplete()
    -- Remove the EMC from the player.
    player.consumeCurrency(self.mainEmc, self.count)
  end

  --Set up the function for constructing the objective text
  function gatherEmcCondition:objectiveText()
    local objective = self.description
    objective = objective:gsub("<required>", self.count)
    objective = objective:gsub("<current>", player.currency(self.mainEmc))
    return objective
  end

  return gatherEmcCondition
end

function buildStudyTransmutationCondition(config)
  --Set up the monster kill condition
  local studyEmcCondition = {
    description = config.description,
    mainEmc = config.mainEmc,
    count = config.count or 1,
    playerCount = 0
  }

  --Set up the function for checking if the conditions were met
  function studyEmcCondition:conditionMet()
    -- Check if the player knowns some transmutations.
    local playerTransmutations = player.getProperty("eesTransmutations")
    if not playerTransmutations or not playerTransmutations[self.mainEmc] then
      return false
    end

    -- Count the relevant transmutations.
    self.playerCount = 0
    local transmutationList = playerTransmutations[self.mainEmc]
    for k, transmutation in pairs(transmutationList) do
      if transmutation.known then self.playerCount = self.playerCount + 1 end
    end

    return self.playerCount >= self.count
  end

  --Set up the function for performing actions upon quest complete
  function studyEmcCondition:onQuestComplete()
    --Nothing here!
  end

  --Set up the function for constructing the objective text
  function studyEmcCondition:objectiveText()
    local objective = self.description
    objective = objective:gsub("<required>", self.count)
    objective = objective:gsub("<current>", self.playerCount)
    return objective
  end

  return studyEmcCondition
end
