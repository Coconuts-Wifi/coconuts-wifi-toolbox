require( "class" )

-------------------------------------------------------------------------------
-- A class to fetch network statistics and return it in JSON form -------------
-------------------------------------------------------------------------------
class "ccwNetStats"

--Init function for object
function ccwNetStats:ccwNetStats()

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
        
function ccwNetStats:getVersion()
  return self.version
end

function ccwNetStats:getWifi()
  return self:_getWifi()
end

function ccwNetStats:log(m,p)
  if(self.debug)then
    self.logger:log(m,p)
  end
end
--[[--
========================================================
=== Private functions start here =======================
========================================================
--]]--

function ccwNetStats._getMac(self)
  --we assume each device will at least have an eth0            
  io.input("/sys/class/net/eth0/address")
  local mac = io.read("*line")
  return mac
end

function ccwNetStats._getWifi(self)
  self:log('Getting WiFi stats')
  local w 	  = {}

  --Add the eth0 addy which is used as the key and we assume each device will at least have an eth0            
  io.input("/sys/class/net/eth0/address")                                                                      
  w['eth0']       = io.read("*line") 

  -- initialize wifi array
  w['wifi']     = {}  

  local phy 	  = nil
  local i_info	= {}

  local dev = self.external:getOutput("iw dev")
  for line in string.gmatch(dev, ".-\n")do
    
    line = line:gsub("^%s*(.-)%s*$", "%1")

    if(line:match("^phy#"))then
      --Get the interface number 
      phy = line:gsub("^phy#", '')
    end

    if(line:match("^Interface "))then
      line = line:gsub("^Interface ", '')
      i_info['name']	= line
    end

    if(line:match("^addr "))then
      line = line:gsub("^addr ", '')
      i_info['mac']	= line
    end

    if(line:match("^ssid "))then
      line = line:gsub("^ssid ", '')
      i_info['ssid']	= line
    end

    if(line:match("^channel "))then
      line = line:gsub("^channel ", '')
      i_info['channel']	= line
    end	

    if(line:match("^txpower "))then
      line = line:gsub("^txpower ", '')
      i_info['txpower']	= line
    end	

    if(line:match("^type "))then
      line = line:gsub("^type ", '')
      i_info['type']	= line
    end

    -- 	--This is our last search now we can add the info
      
    -- 	--Sometimes the ssid is not listed per interface, then we have to search for it
    -- 	if(i_info['ssid'] == nil)then
    -- 		i_info['ssid'] = self._getSsidForInterface(self,i_info['name']);
    -- 		--print(i_info['ssid']);	
    -- 	end

    if(phy and i_info['name'] and i_info['mac'] and i_info['ssid'] and i_info['type'] and i_info['channel'] and i_info['txpower'])then
      local config    = {}

      local want_these= {
        'hwmode', 'antenna', 'txpower', 'channel', 'htmode', 'disabled'
      }
      for i, v in ipairs(want_these) do
        local value = self.external:getOutput("uci get wireless.radio"..phy.."."..v)
        config[v] = value:gsub("[\n]", "")
      end

      local stations 	= {}
      local stations 	= self._getStations(self, i_info['name'])

      table.insert(w['wifi'], { radio=phy, channel = i_info['channel'], txpower = i_info['txpower'], type= i_info['type'], name= i_info['name'], mac = i_info['mac'], ssid = i_info['ssid'], config = config, stations = stations })

      i_info['ssid'] = nil --zero it again for the next round
    end

  end
  return self.json.encode(w)
end

function ccwNetStats._getStations(self,interface)

  self:log('Getting Stations connected to '..interface)
  local s 	    = {}
  local s_info	= {}

  local want_these= {
    'inactive time', 'rx bytes', 'tx bytes', 'tx retries', 'tx failed', 'signal', 'signal avg', 'tx bitrate', 'rx bitrate', 'expected throughput',
    'authorized', 'authenticated', 'associated', 'preamble', 'beacon interval', 'connected time'
  }
  -- local last_item = "connected time"
  local size_want_these = table.getn(want_these)
  
  local dev = self.external:getOutput("iw dev "..interface.." station dump")
  for line in string.gmatch(dev, ".-\n")do	--split it up on newlines
    
    line = line:gsub("^%s*(.-)%s*$", "%1")  --remove leading and trailing spaces
    if(line:match("^Station"))then
      line = line:gsub("^Station-%s(.-)%s.+","%1")
      s_info['mac'] = line
    end
    
    for i, v in ipairs(want_these) do 
      local l = line

      if(line:match("^"..v..":-%s"))then
        if(l:match("^signal avg:"))then --avoid catching 'signal avg'
          line  	 	 = line:gsub("signal avg:-%s+","")
          -- print("^signal avg:" .. line)
          s_info["signal_avg"] 	= line
        else
          line  	 	 = line:gsub(v..":-%s+","")
          local name = v:gsub(" ", '_')
          -- print(" key: " .. v .. " value: " .. line)
          s_info[name] = line
        end

        if(i == size_want_these)then
          table.insert(s, s_info)
          s_info	= {}
        end
      end
    end
  end
  return s
end

function ccwNetStats._getSsidForInterface(self,interface)
  local retval = nil
  self.x.foreach('wireless','wifi-iface', 
    function(a)
      --print(a['.name'].." "..interface)
      --Check the name--
      if(string.find(a['ifname'], interface))then
        retval = a['ssid']
      end
     end)
  return retval
end

function ccwNetStats._createWirelessLookup(self)
  --This will create a lookup on the object to determine the hardware mode a wifi-device has
  --So we only call this once
 
  local default_val = 'g' --We specify a 'sane' default of g	
  self.x.foreach('wireless','wifi-device', 
  function(a)
    local dev_name 	= a['.name'];
    local hwmode 	= a['hwmode'];
    if(hwmode == nil)then
      hwmode = default_val;
    end
    self[dev_name] = {}; --empty table
    self[dev_name]['hwmode'] = hwmode;
  end)

  self.x.foreach('wireless','wifi-iface', 
    function(a)
      --print(a['.name'].." "..interface)
      --Check the name--
      local ifname = a['ifname'];
      local device = a['device'];
      if(ifname ~= nil)then
        self[ifname] = a;
        --print(self[ifname]['device']);	
      end
  end)
end
