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

function retrieveActions()

  -- System info --
  require("ccwSystem")
  local s = ccwSystem()
  local hostname = s:property('hostname')

  -- Retrieve Server
  local server = s:property('server_toolbox')
  local query = server..'/core/rpc'

  -- Retrieve Server Key
  local ssk = s:property('server_stats_key')

  --Remove old actions
  os.remove(action_file)

  --Remove call the server
  local curl_data = '{ "jsonrpc":"2.0", "method":"antenna.retrieve_action", "params": { "hostname": "'..hostname..'" }, "id": 1}'
  os.execute("curl -X POST "..query.." -H 'Content-Type: application/json' -o "..action_file.." -d '"..curl_data.."'")

  -- Read the answer from server
  local file = assert(io.open(action_file, "r"))
  local content = file:read "*all" -- *a or *all reads the whole file
  file:close()

  os.execute("echo "..content)

  json = require("json")
  local answer = json.decode(content)
  if answer.error then return print(answer.error.code.." "..answer.error.message) end

  os.execute("echo "..answer.result.action.cmd)

  --HMAC 512
  local sha = require("sha2")
  local strAction = answer.result.action
  local hmac = sha.hmac(sha.sha256, ssk, hostname..'/'..strAction)

  --Treatment
  local action = json.decode(strAction)
  if(hmac == answer.result.signature)then
    if(action.cmd == 'update')then
      if(action.section == 'system')then
        for k, v in pairs(action.data) do
          print(k, v)
          local res = s:property(k, v)
          print(res)
        end
      end
    end
  end
end

retrieveActions()