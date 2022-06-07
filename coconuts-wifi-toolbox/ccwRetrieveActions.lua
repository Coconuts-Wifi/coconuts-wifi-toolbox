#!/usr/bin/lua

-- ________________________________________________________________________
--
-- Run by crond to send antenna stats
--

-- Include libraries
package.path = "/etc/coconuts-wifi-toolbox/libs/?.lua;" .. package.path

local uci = require("uci")
x = uci.cursor(nil,'/var/state')

local action_file = '/tmp/action.json'
local resp_file = '/tmp/resp_action.json'

function retrieveActions()

  -- System info --
  require("ccwSystem")
  local s = ccwSystem()
  local hostname = s:property('hostname')

  -- Network info --
  require("ccwNetStats")
  local n = ccwNetStats()
  local mac = n:_getMac()

  -- Retrieve Server
  local server = s:property('server_toolbox')
  local query = server..'/core/rpc'

  -- Retrieve Server Key
  local ssk = s:property('server_toolbox_key')

  --Remove old actions
  os.remove(action_file)
  os.remove(resp_file)

  -- call the server
  local curl_data = '{ "jsonrpc":"2.0", "method":"antenna.retrieve_action", "params": { "hostname": "'..hostname..'", "mac": "'..mac..'" }, "id": 1}'
  os.execute("curl --silent --insecure -X POST "..query.." -H 'Content-Type: application/json' -o "..action_file.." -d '"..curl_data.."'")

  -- Read the answer from server
  local file = assert(io.open(action_file, "r"))
  local content = file:read "*all" -- *a or *all reads the whole file
  file:close()

  json = require("json")
  local answer = json.decode(content)
  if answer.error then return print(answer.error.code.." "..answer.error.message) end

  --HMAC 512
  local sha = require("sha2")
  local strAction = answer.result.action
  local hmac = sha.hmac(sha.sha256, ssk, hostname..'/'..strAction)

  -- Check file function
  function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
  end

  --Treatment
  local a = json.decode(strAction)
  if(hmac == answer.result.signature)then

    --[[--
    ========================
    ===   ccwActionCmd   ===
    ========================
    --]]--
    if(a.action.uci == 'ccwActionCmd')then
      local data = {}

      --  if Wifi scan
      if(a.action.data.cmd == 'wifi_scan')then
        require("ccwWifiScan")
        local ws = ccwWifiScan()
        local neighborhood = ws:_getNeighborhood('coconuts0')
        -- ws:_console(neighborhood)
        data = json.encode(neighborhood)
      end

      --  if Ping
      if(a.action.data.cmd == 'ping')then
        local address = a.action.data.options._ip
        require("ccwPing")
        local ping = ccwPing()
        local ping_result = ping:_ping(address)

        data = json.encode(ping_result)
      end

      -- if Speedtest
      if(a.action.data.cmd == 'speedtest')then
        local address = a.action.data.options._address
        local port = a.action.data.options._port
        local length = a.action.data.options._length
        require("ccwSpeed")
        local speed = ccwSpeed()
        local speed_result = speed:_iperf3(address, port, length)

        data = json.encode(speed_result)
      end

      -- if Reboot
      if(a.action.data.cmd == 'reboot' or a.action.data.cmd == 'upgrade')then
        -- Update case
        if(a.action.data.cmd == 'upgrade')then
          -- Retrieve firmware
          os.execute("curl --silent --insecure -X GET "..server.."/core/public/"..a.action.data.options._firmware.." -H 'Content-Type: application/json' -o /tmp/"..a.action.data.options._firmware)
        end

        -- Send the result
        local resp_data = '{ "jsonrpc":"2.0", "method":"antenna.update_action", "params": { "_id": "'..a.action_id..'", "success": true }, "id": 1}'
        os.execute("curl --silent --insecure -X POST "..query.." -H 'Content-Type: application/json' -o "..resp_file.." -d '"..resp_data.."'")

        -- Update case
        if(a.action.data.cmd == 'upgrade')then
          os.execute("sysupgrade -v /tmp/"..a.action.data.options._firmware)
        -- Reboot case
        else
          print("echo REBOOT...")
          os.execute("reboot")
        end

      else
        -- Send the result
        local resp_data = '{ "jsonrpc":"2.0", "method":"antenna.update_action", "params": { "_id": "'..a.action_id..'", "success": true, "data": '..data..' }, "id": 1}'
        os.execute("curl --silent --insecure -X POST "..query.." -H 'Content-Type: application/json' -o "..resp_file.." -d '"..resp_data.."'")
      end
    end

    --[[--
    =======================
    ===   ccwWireless   ===
    =======================
    --]]--
    if(a.action.uci == 'ccwWireless')then
      -- update wifi-device
      for k, v in pairs(a.action.data.wifiDevice) do
        os.execute("uci set wireless.radio"..a.action.data.radio_number.."."..k.."="..v)
      end
      os.execute("uci commit wireless")
      os.execute("wifi")

      -- Send the result
      local resp_data = '{ "jsonrpc":"2.0", "method":"antenna.update_action", "params": { "_id": "'..a.action_id..'", "success": true, "data": {} }, "id": 1}'
      os.execute("curl --silent --insecure -X POST "..query.." -H 'Content-Type: application/json' -o "..resp_file.." -d '"..resp_data.."'")
    end

  end
end

retrieveActions()