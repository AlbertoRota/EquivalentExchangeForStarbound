function EES_getItemConfig(itemDesc)
  -- Initiallyze cache.
  if not self.itemConfigCache then self.itemConfigCache = {} end

	if not itemDesc then
    -- No item passed, skip.
    sb.logWarn("EES_log - EES_getItemConfig: Called 'EES_getItemConfig' with a 'nil' value.")
		return
	elseif type(itemDesc) ~= "table" then
    -- Only name provided, create dummy "itemDesc".
		itemDesc = {name = itemDesc, count = 1, parameters = {}}
	end

	if not self.itemConfigCache[itemDesc.name] then
    -- Item not cached, initiallize it.
		local default = root.itemConfig(itemDesc)
		if default then
      local cfg = default.config
			self.itemConfigCache[itemDesc.name] = {
        itemName = cfg.itemName,
				maxStack = (cfg.category and cfg.category == "Blueprint" and 1) or
                    cfg.maxStack or
                    root.assetJson("/items/defaultParameters.config:defaultMaxStack"),
				price = cfg.price or 0,
				shortdescription = cfg.shortdescription
			}
		else
      sb.logWarn("EES_log - EES_getItemConfig: Unable to properly parse: %s", itemDesc.name)
			self.itemConfigCache[itemDesc.name] = {}
		end
	end
  
	return self.itemConfigCache[itemDesc.name]
end


-- Prints all the tables available in the environment
function tprint (tbl, msg)
  sb.logInfo("/* **************************** */")
  sb.logInfo("EES_log - Printing: " .. msg)
  if not tbl then
    sb.logInfo("Is nill")
  elseif type(tbl) == "table" then
    __tprintloop (tbl, indent)
  else
    sb.logInfo("Not a table (" .. type(tbl) .. "): " .. tostring(tbl))
  end
  sb.logInfo("/* **************************** */")
end

function __tprintloop (tbl, indent)
  if not indent then indent = 0 end

  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      sb.logInfo(formatting)
      __tprintloop(v, indent+1)
    else
      sb.logInfo(formatting .. tostring(v))
    end
  end
end
