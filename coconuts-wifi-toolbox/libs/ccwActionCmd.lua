require( "class" )

-------------------------------------------------------------------------------
-- Class used to get/set the system settings ----------------------------------
-------------------------------------------------------------------------------
class "ccwActionCmd"

function ccwActionCmd.exec(cmd)
  --Reboot
  if(cmd == 'reboot')then
    os.execute("reboot")
  end

  --Activate it if hostname
  if(property == 'hostname')then
    os.execute("echo "..value.." > /proc/sys/kernel/hostname")
  end

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