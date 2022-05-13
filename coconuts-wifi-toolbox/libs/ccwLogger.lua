require( "class" )
class "ccwLogger"

--Init function for object
function ccwLogger:ccwLogger()
	self.version 	= "1.0.1"
	self.tag    	= "Coconuts"
	self.priority	= "debug"
end
        
function ccwLogger:getVersion()
	return self.version
end


function ccwLogger:log(message,priority)
	priority = priority or self.priority
	os.execute("logger -t " .. self.tag .. " -p " .. priority .. " " .. message)
end