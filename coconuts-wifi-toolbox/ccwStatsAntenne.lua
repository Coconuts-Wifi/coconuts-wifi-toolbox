#!/usr/bin/lua

-- ________________________________________________________________________
--
-- Run by crond to send antenna stats
--

-- Include libraries
package.path       = "/etc/coconuts-wifi-toolbox/libs/?.lua;" .. package.path

local result_file  = '/tmp/result.json'
local new_json     = '/tmp/send.json'

function submitReport()

  -- Retrieve hostname
  require("ccwSystem")
  local s = ccwSystem()
  local hostname = s:property('hostname')

  -- Retrieve Server
  local server = s:property('server_toolbox')
  local query = server..'/core/rpc'

  -- Retrieve Server Key
  local ssk = s:property('server_stats_key')

  -- System info --
  require("ccwSystemStats")
  local s         = ccwSystemStats()
  local s_stats   = s:getStats()
  -- os.execute("echo "..s_stats)

  -- Network info --
  require("ccwNetStats")
  local n         = ccwNetStats()
  local n_stats   = n:getWifi()
  -- os.execute("echo "..n_stats)

  -- Retrieve LAN IP ADDRESS --
  local socket = require("socket")
  local someRandomIP = "192.168.1.122" --This address you make up
  local someRandomPort = "3102"        --This port you make up
  local mySocket = socket.udp()        --Create a UDP socket like normal

  --This is the weird part, we need to set the peer for some reason
  mySocket:setpeername(someRandomIP,someRandomPort)

  --Then we can obtain the correct ip address and port
  local myDevicesIpAddress, somePortChosenByTheOS = mySocket:getsockname() -- returns IP and Port

  --HMAC 512
  local sha = require("sha2")
  local hmac = sha.hmac(sha.sha256, ssk, hostname..'/'..myDevicesIpAddress)

  --Prepare Data to send
  local curl_data = '{"jsonrpc":"2.0", "method":"antenna.update_status", "params":{"hostname":"'..hostname..'", "address":"'..myDevicesIpAddress..'", "system":'..s_stats..', "network":'..n_stats..', "signature":"'..hmac..'"}, "id":1}'

  local envoiJSON,err = io.open(new_json,"w")
  if not envoiJSON then return print(err) end
  envoiJSON:write(curl_data)
  envoiJSON:close()

  --Remove old results
  os.remove(result_file)
  os.execute('curl -o '..result_file..' -X POST -H "Content-Type: application/json" -d @'..new_json..' '..query)

end

submitReport()