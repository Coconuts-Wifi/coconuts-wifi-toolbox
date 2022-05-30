require( "class" )

-------------------------------------------------------------------------------
-- Class used to get/set the system settings ----------------------------------
-------------------------------------------------------------------------------
class "ccwSpeed"

--Init function for object
function ccwSpeed:ccwSpeed()
  require('ccwLogger')
  require('ccwExternal');
  require("ccwPing")
  local uci = require('uci')

  self.version = "0.0.1"
  self.debug = true
  self.external	= ccwExternal()
  self.ping = ccwPing()
  self.json = require("json")
  self.logger = ccwLogger()
  self.x = uci.cursor(nil,'/var/state')
end

function ccwSpeed:getVersion()
  return self.version
end

function ccwSpeed:log(m,p)
  if(self.debug)then
    self.logger:log(m,p)
  end
end

--[[--
========================================================
=== Private functions start here =======================
========================================================
--]]--

function ccwSpeed._iperf3(self, address, port, length)
  local result = {}

  print("Speedtest "..address.." port: "..port.." length: "..length.." sec")

  -- upload
  result["upload"] = self.external.getOutput("iperf3 -c %s -p %s -t %s -4 -J" % { address, port, length })
  -- local upload = io.popen("iperf3 -c %s -p %s -t %s -4 -J" % { address, port, length })
  -- result["upload"] = upload:read("*a")
  -- upload:close()
  
  -- download
  result["download"] = self.external.getOutput("iperf3 -c %s -p %s -t %s -4 -J -R" % { address, port, length })
  -- local download = io.popen("iperf3 -c %s -p %s -t %s -4 -J -R" % { address, port, length })
  -- result["download"] = upload:read("*a")
  -- download:close()

  -- ping
  result["ping"] = self.ping._ping(address)

  return result
end