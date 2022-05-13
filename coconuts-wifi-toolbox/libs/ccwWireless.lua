require( "class" )

-------------------------------------------------------------------------------
-- Class used to get/set the system settings ----------------------------------
-------------------------------------------------------------------------------
class "ccwWireless"

--Init function for object
function ccwWireless:ccwWireless()
  require('ccwLogger')
  local uci = require('uci')
  self.version = "0.0.1"
  self.debug = true
  self.json = require("json")
  self.logger = ccwLogger()
  self.x = uci.cursor(nil,'/var/state')
end

function ccwWireless:getVersion()
  return self.version
end

function ccwWireless:log(m,p)
  if(self.debug)then
    self.logger:log(m,p)
  end
end

--[[--
========================================================
=== Private functions start here =======================
========================================================
--]]--

function ccwWireless.radio(self, radio_number, property, value)
  local device = 'radio'..radio_number
  local v = nil
  if(value ~= nil)then
    self.x.set('wireless', device, property, value)
    self.x.commit('wireless')
  end
  v = self.x.get('wireless', device, property)
  return v
end

function ccwWireless.iface(self, iface_number, property, value)
  local iface = '@wifi-iface['..iface_number..']'
  local v = nil
  if(value ~= nil)then
    -- self.x.set('wireless', device, property, value)
    -- self.x.commit('wireless')
  end
  v = self.x.get('wireless', device, property)
  return v
end