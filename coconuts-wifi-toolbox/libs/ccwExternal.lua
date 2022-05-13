require( "class" )

-------------------------------------------------------------------------------
-- Object to manage external programs (start and stop) ------------------------
-------------------------------------------------------------------------------
class "ccwExternal"

--Init function for object
function ccwExternal:ccwExternal()
	self.version 	= "0.0.1"
end
        
function ccwExternal:getVersion()
	return self.version
end

function ccwExternal:start(program)
	os.execute(program)
end

function ccwExternal:startOne(program,kill)
	print(program)
	if(kill)then
		if(self:pidof(kill))then
			os.execute("killall "..kill)
		end
	end
	os.execute(program)
end


function ccwExternal:stop(program)
	if(self:pidof(program))then
		os.execute("killall "..program)
	end
end

function ccwExternal:getOutput(command)
	local handle = io.popen(command)                                      
        local result = handle:read("*a")                                                 
        handle:close()  
	return result
end

function ccwExternal:pidof(program)
	local handle = io.popen('pidof '.. program)                                      
        local result = handle:read("*a")                                                 
        handle:close()  
	result = string.gsub(result, "[\r\n]+$", "")                                     
	if(result ~= nil)then      
		if(tonumber(result) == nil)then --if more than one is running we simply return true
			if(string.len(result) > 1)then
				return true
			else
				return false
			end
		else                                                      
			return tonumber(result)
		end                                                  
	else      
		return false                                                             
	end 
end

--[[--
========================================================
=== Private functions start here =======================
========================================================
--]]--

