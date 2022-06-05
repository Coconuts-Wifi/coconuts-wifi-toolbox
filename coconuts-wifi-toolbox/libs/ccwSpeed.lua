require( "class" )

-------------------------------------------------------------------------------
-- Class used to get/set the system settings ----------------------------------
-------------------------------------------------------------------------------
class "ccwSpeed"

--Init function for object
function ccwSpeed:ccwSpeed()
  require('ccwLogger')
  local uci = require('uci')

  self.version = "0.0.1"
  self.debug = true
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
  local upload = io.popen("iperf3 -c "..address.." -p "..port.." -t "..length.." -4 -J")
  local upload_txt = upload:read("*a")
  upload_txt = upload_txt.gsub(upload_txt,"\r?\n|\r","")
  result["upload"] = json.decode(upload_txt)
  upload:close()
  
  -- download
  local download = io.popen("iperf3 -c "..address.." -p "..port.." -t "..length.." -4 -J -R")
  local download_txt = download:read("*a")
  download_txt = download_txt.gsub(download_txt,"\r?\n|\r","")
  result["download"] = json.decode(download_txt)
  download:close()

  -- ping
  require("ccwPing")
  local ping = ccwPing()
  result["ping"] = ping:_ping(address)

  return result
end