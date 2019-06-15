-- Prints all the tables available in the environment
function envprint (msg)
  sb.logInfo("/* **************************** */")
  sb.logInfo("Printing _ENV: " .. msg)
  for k, v in pairs(_ENV) do
    sb.logInfo( k .. ": " .. tostring(v) )
  end
  sb.logInfo("/* **************************** */")
end

function traceprint (msg)
  sb.logInfo("/* **************************** */")
  sb.logInfo( msg )
  sb.logInfo("/* **************************** */")
end

function tprint (tbl, msg)
  sb.logInfo("/* **************************** */")
  sb.logInfo("Printing: " .. msg)
  if not tbl then
    sb.logInfo("Is nill")
  elseif type(tbl) == "table" then
    __tprintloop (tbl, indent)
  else
    sb.logInfo("Not a table: " .. tostring(tbl))
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
