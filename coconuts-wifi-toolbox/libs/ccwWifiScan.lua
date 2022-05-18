require( "class" )

-------------------------------------------------------------------------------
-- A class to fetch network statistics and return it in JSON form -------------
-------------------------------------------------------------------------------
class "ccwWifiScan"

--Init function for object
function ccwWifiScan:ccwWifiScan()

	require('ccwLogger');
	require('ccwExternal');
	local uci 		= require("uci")

	self.version 	= "1.0.0"
	self.json		  = require("json")
	self.logger	  = ccwLogger()
	self.external	= ccwExternal()
	self.debug		= true
	self.x		  	= uci.cursor(nil,'/var/state')
	
end

--[[--
========================================================
=== Private functions start here =======================
========================================================
--]]--

function ccwWifiScan._getNeighborhood(self, devname)
	local csv = self.external:getOutput("iw "..devname.." scan | gawk -f /etc/coconuts-wifi-toolbox/gawk/wifi-scan.gawk")

  local neighborhood = {}
  local headers = {}
  local first = true

	for line in csv:gmatch("[^\n]+")do
    if first then                       -- this is to handle the first line and capture our headers.
      local count = 1
      for header in line:gmatch("[^;]+") do 
        headers[count] = header
        count = count + 1
      end
      first = false                     -- set first to false to switch off the header block
    else
      local item = {}
      local i = 1

      for field in line:gmatch("[^;]+") do
        item[headers[i]] = field
        i = i + 1
      end

      table.insert(neighborhood, item)
    end
  end
  return neighborhood
end

-- Output the neighborhood in console
function ccwWifiScan._console(self, neighborhood)
  -- print table out
  print("neighborhood = [")
  for k, item in pairs(neighborhood) do
    print("    {")
    for field, value in pairs(item) do
      print("        " .. field .. ": ".. value .. ",")
    end
    print("    }")
  end
  print("]")
end