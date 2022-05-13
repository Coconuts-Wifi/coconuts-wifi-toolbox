require( "class" )

-------------------------------------------------------------------------------
-- A class to fetch system statistics and return it in JSON form -------------
-------------------------------------------------------------------------------
class "ccwSystemStats"

--Init function for object
function ccwSystemStats:ccwSystemStats()
	require('ccwLogger');
	require('ccwExternal');
	self.version  	= "0.0.1"
	self.json	    = require("json")
	self.logger	    = ccwLogger()
	self.external  	= ccwExternal()
	self.debug	    = true
end
        
function ccwSystemStats:getVersion()
	return self.version
end


function ccwSystemStats:getStats()
	return self:_getStats()
end


function ccwSystemStats:log(m,p)
	if(self.debug)then
		self.logger:log(m,p)
	end
end

--[[--
========================================================
=== Private functions start here =======================
========================================================
(Note they are in the pattern function <ccwName>._function_name(self, arg...) and called self:_function_name(arg...) )
--]]--


function ccwSystemStats._getStats(self)
	self:log('Getting System stats')
	local s 	= {}

	--Add the eth0 addy which is used as the key and we assume each device will at least have an eth0            
	io.input("/sys/class/net/eth0/address")                                                                      
	s['eth0']   = io.read("*line") 

  --Read the memory
  local file = assert(io.open("/proc/meminfo", "r"))
  s['memory'] = {}
  for line in file:lines() do 
      if(string.find(line, "MemTotal:"))then
          local mt = string.gsub(line, "^MemTotal:%s*", "")
          s['memory']['total'] = mt
      end
      if(string.find(line, "MemFree:"))then
          local mf = string.gsub(line, "^MemFree:%s*", "")
          s['memory']['free'] = mf
      end
  end
  file:close()
  
  --Read the CPU info
  local file = assert(io.open("/proc/cpuinfo","r"))
  s['cpu'] = {}
  for line in file:lines() do
      if(string.find(line, "system type%s*:"))then
          local i = string.gsub(line, "^system type%s*:%s*", "")
          s['cpu']['system_type'] = i
      end
      if(string.find(line, "machine%s*:"))then
          local i = string.gsub(line, "^machine%s*:%s*", "")
          s['cpu']['machine'] = i
      end
      if(string.find(line, "cpu model%s*:"))then
          local i = string.gsub(line, "^cpu model%s*:%s*", "")
          s['cpu']['cpu_model'] = i
      end
      if(string.find(line, "BogoMIPS%s*:"))then
          local i = string.gsub(line, "^BogoMIPS%s*:%s*", "")
          s['cpu']['BogoMIPS'] = i
      end
  end
  file:close()
  
  --Get the uptime
  local handle = assert(io.open("/proc/uptime","r"))                                      
  local result = handle:read("*a")
  result = string.gsub(result,",","")
  result = string.gsub(result,"\n","")
  
  handle:close()  
  s['uptime'] = result

  --Get the uptime long
  local handle = io.popen("uptime")                                      
  local result = handle:read("*a")
  result = string.gsub(result,"^%s*","")
  result = string.gsub(result,"\n","") 

  handle:close()  
  s['uptime_long'] = result

  --get the release
  local file = assert(io.open("/etc/openwrt_release", "r"))
  s['release'] = {}

  for line in file:lines() do
      if(string.find(line, "DISTRIB_ID="))then
          local i = string.gsub(line, "^DISTRIB_ID=", "")
          local ii = string.gsub(i, "'", "\"")  
          s['release']['distribution'] = ii
      end
      if(string.find(line, "DISTRIB_RELEASE="))then
          local i = string.gsub(line, "^DISTRIB_RELEASE=", "")
          local ii = string.gsub(i, "'", "\"")
          s['release']['release'] = ii
      end
      if(string.find(line, "DISTRIB_REVISION="))then
          local i = string.gsub(line, "^DISTRIB_REVISION=", "")
          local ii = string.gsub(i, "'", "\"")
          s['release']['revision'] = ii
      end
      if(string.find(line, "DISTRIB_TARGET="))then
          local i = string.gsub(line, "^DISTRIB_TARGET=", "")
          local ii = string.gsub(i, "'", "\"")
          s['release']['target'] = ii
      end
      if(string.find(line, "DISTRIB_DESCRIPTION="))then
          local i = string.gsub(line, "^DISTRIB_DESCRIPTION=", "")
          local ii = string.gsub(i, "'", "\"")
          s['release']['description'] = ii
      end        
  end
  return (self.json.encode(s)) 	
end 