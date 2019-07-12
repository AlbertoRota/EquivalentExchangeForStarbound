-- An expansion on the vanilla main quest script
-- Overrides the buildConditions function, allowing for additional condition
require "/quests/scripts/main.lua"
require('/quests/ees/scripts/EES_conditionBuilder.lua')

EES_SuperBuildConditions = buildConditions
function buildConditions()
  -- Call the Vanilla method
  local conditions = EES_SuperBuildConditions()

  -- Enrich with the custom conditions
  local conditionConfig = config.getParameter("conditions", {})
  for _,config in pairs(conditionConfig) do
    local newCondition
    if config.type == "gatherEmc" then
      newCondition = buildGatherEmcCondition(config)
    elseif config.type == "studyTransmutation" then
      newCondition = buildStudyTransmutationCondition(config)
    end
    table.insert(conditions, newCondition)
  end

  return conditions
end
