require( "class" )

-------------------------------------------------------------------------------
-- Class used to get/set the system settings ----------------------------------
-------------------------------------------------------------------------------
class "ccwSystem"

--Init function for object
function ccwSystem:ccwSystem()
  require('ccwLogger')
  local uci = require('uci')
  self.version = "0.0.1"
  self.debug = true
  self.json = require("json")
  self.logger = ccwLogger()
  self.x = uci.cursor(nil,'/var/state')
end

function ccwSystem:getVersion()
  return self.version
end

function ccwSystem:log(m,p)
  if(self.debug)then
    self.logger:log(m,p)
  end
end

--[[--
========================================================
=== Private functions start here =======================
========================================================
--]]--

function ccwSystem.property(self, property, value)
  local p = nil

  if(value ~= nil)then
    self.x.foreach('system','system', 
      function(a)
        self.x.set('system', a['.name'], property, value)
    end)
    self.x.commit('system')
    --Activate it if hostname
    if(property == 'hostname')then
      os.execute("echo "..value.." > /proc/sys/kernel/hostname")
    end
  end

  self.x.foreach('system','system', 
    function(a)
       p = self.x.get('system', a['.name'], property)
  end)
  return p
end