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
  os.execute("curl --insecure -X POST "..query.." -H 'Content-Type: application/json' -o "..action_file.." -d '"..curl_data.."'")

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

  --Treatment
  -- local action = json.decode(strAction)
  -- if(hmac == answer.result.signature)then
  --   if(action.cmd == 'update')then
  --     if(action.section == 'system')then
  --       for k, v in pairs(action.data) do
  --         print(k, v)
  --         local res = s:property(k, v)
  --         print(res)
  --       end
  --     end
  --   end
  -- end

  --Treatment
  local a = json.decode(strAction)
  os.execute("echo "..a.action_id)
  if(hmac == answer.result.signature)then
    -- ccwActionCmd
    if(a.action.uci == 'ccwActionCmd')then
      -- if Reboot
      if(a.action.data == 'reboot')then
        -- call the server first (due to reboot)
        local resp_data = '{ "jsonrpc":"2.0", "method":"antenna.update_action", "params": { "_id": "'..a.action_id..'", "success": true }, "id": 1}'
        os.execute("curl --insecure -X POST "..query.." -H 'Content-Type: application/json' -o "..resp_file.." -d '"..resp_data.."'")
        os.execute(reboot)
      end

      --  if Wifi scan
      if(a.action.data == 'wifi_scan')then
        require("ccwWifiScan")
        local ws = ccwWifiScan()
        local neighborhood = ws:_getNeighborhood('coconuts0')
        ws:_console(neighborhood)
        local data = json.encode(neighborhood)
        -- Send the result
        local resp_data = '{ "jsonrpc":"2.0", "method":"antenna.update_action", "params": { "_id": "'..a.action_id..'", "success": true, "data": '..data..' }, "id": 1}'
        os.execute("curl --insecure -X POST "..query.." -H 'Content-Type: application/json' -o "..resp_file.." -d '"..resp_data.."'")
      end
    end
  end
end

retrieveActions()