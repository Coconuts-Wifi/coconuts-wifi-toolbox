require( "class" )

-------------------------------------------------------------------------------
-- Class used to get/set the system settings ----------------------------------
-------------------------------------------------------------------------------
class "ccwPing"

--Init function for object
function ccwPing:ccwPing()
  require('ccwLogger')
  local uci = require('uci')
  self.version = "0.0.1"
  self.debug = true
  self.json = require("json")
  self.logger = ccwLogger()
  self.x = uci.cursor(nil,'/var/state')
end

function ccwPing:getVersion()
  return self.version
end

function ccwPing:log(m,p)
  if(self.debug)then
    self.logger:log(m,p)
  end
end

--[[--
========================================================
=== Private functions start here =======================
========================================================
--]]--

function ccwPing._ping(self, ip)
  local result = {}

  print("Pinging "..ip)
  local output = io.popen("ping -c 5 -i 1 -w 4 "..ip)
  for line in output:lines() do
    local parsed_line

    -- PING first line
    if line:match("^PING") then
      result.target = line:match("^PING%s(%d*%.%d*%.%d*%.%d*)%s")
    end

    -- Min, Max, Avg
    if line:match("^round%-trip") then
      print(line)
      local min, avg, max = line:match("^.-%=%s(%d*%.?%d*)%/(%d*%.?%d*)%/(%d*%.?%d*)%s")
      result.min = min
      result.avg = avg
      result.max = max
    end

    if line:match("^%d.-loss$") then
      result.loss = line:match("^%d.-%,%s(%d*%%)%spacket%sloss$")
    end
  end
  output:close()
  return result
end
