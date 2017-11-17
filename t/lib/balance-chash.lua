-- Copyright (C) 2017 Libo Huang (huangnauh), UPYUN Inc.

local consistent_hash = require "resty.checkups.consistent_hash"

local VNODES    = 1024
local local_dir = arg[1]

-- ngx.say("local dir: ", local_dir)

package.path = local_dir .. "/lib/?.lua;" .. package.path
package.cpath = local_dir .. "/?.so;" .. package.cpath

local servers = {
    { host = "192.168.11.11", port = 12354, weight = 1 },
    { host = "192.168.11.12", port = 12354, weight = 1 },
}

local new_servers = {
    { host = "192.168.11.11", port = 12354, weight = 1 },
    { host = "192.168.11.12", port = 12354, weight = 1 },
    { host = "192.168.11.13", port = 12354, weight = 1 },
}

consistent_hash.init_consistent_hash_state(servers)
local h1 = servers.chash
consistent_hash.init_consistent_hash_state(new_servers)
local h2 = new_servers.chash

local cu = 0

local count1 = {}
local count2 = {}
for i=1, VNODES do
    local idx1 = h1.vnodes[i]
    local host1 = servers[h1.circle[idx1][2]]["host"]
    count1[host1] = (count1[host1] or 0) + 1
    local idx2 = h2.vnodes[i]
    local host2 = new_servers[h2.circle[idx2][2]]["host"]
    count2[host2] = (count2[host2] or 0) + 1
    if host1 ~= host2 then
        cu = cu + 1
    end
end

local max, min, sum = 0, VNODES, 0
for key, v in pairs(count1) do
    print("count1:", key, ":", v)
    if v > max then
        max = v
    end

    if v < min then
        min = v
    end

    sum = sum + v
end
print("1 max:", max, ", min:", min, ", avg:", sum/#count1)


local max, min, sum = 0, VNODES, 0
for key, v in pairs(count2) do
    print("count2:", key, ":", v)
    if v > max then
        max = v
    end

    if v < min then
        min = v
    end

    sum = sum + v
end
print("2 max:", max, ", min:", min, ", avg:", sum/#count1)


print("change:", cu, ", ", cu / VNODES, "%")


