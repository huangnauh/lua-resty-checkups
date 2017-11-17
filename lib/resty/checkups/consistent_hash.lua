-- Copyright (C) 2014-2016, UPYUN Inc.

local floor      = math.floor
local str_byte   = string.byte
local tab_sort   = table.sort
local tab_insert = table.insert
local md5_bin    = ngx.md5_bin
local crc32_long = ngx.crc32_long
local ipairs     = ipairs


local _M = { _VERSION = "0.11" }

local MAX       = 2 ^ 32 - 1
local TRIES     = 20
local LUCKY_NUM = 89
local VNODES    = 1024

local function hash_string(key)
	local md5 = md5_bin(key)
	return crc32_long(md5)
end


local function binary_search(circle, key)
    local size = #circle
    local st, ed, mid = 1, size, 0
    while st <= ed do
        mid = floor((st + ed) / 2)
        if circle[mid][1] < key then
            st = mid + 1
        else
            ed = mid - 1
        end
    end

    return st == size + 1 and 1 or st
end


local function init_consistent_hash_state(servers)
    local weight_sum = 0
    for _, srv in ipairs(servers) do
        weight_sum = weight_sum + (srv.weight or 1)
    end

    local replica = 1
    if weight_sum < VNODES then
        replica = floor(VNODES/weight_sum)
    end

    local circle, members = {}, 0
    for index, srv in ipairs(servers) do
        for c = 1, replica * (srv.weight or 1) do
            local key = ("%s:%s:%s"):format(srv.host, srv.port, c)
            local hash = hash_string(key)
            tab_insert(circle, { hash, index })
        end
        members = members + 1
    end

    tab_sort(circle, function(a, b) return a[1] < b[1] end)

    local vnodes = {}
    local step = floor(MAX / VNODES)
    for i=1, VNODES do
		tab_insert(vnodes, binary_search(circle, floor(step * (i - 1))))
	end

    servers.chash =  { circle = circle, vnodes = vnodes, members = members }
    return
end
_M.init_consistent_hash_state = init_consistent_hash_state


function _M.next_consistent_hash_server(servers, peer_cb, hash_key)
    local chash = servers.chash
    if chash.members == 1 then
        if peer_cb(1, servers[1]) then
            return servers[1]
        end

        return nil, "consistent hash: no servers available"
    end

    local st
    for i = 1, TRIES do
        local key = floor(crc32_long(hash_key))
        local vidx = (key + (i - 1) * LUCKY_NUM) % VNODES + 1
        local nidx = chash.vnodes[vidx]
        local idx = chash.circle[nidx][2]
        print("try ", i, " times, server id: ", idx)
        if peer_cb(idx, servers[idx]) then
            return servers[idx]
        end
        st = idx
    end

    local size = #servers
    local ed = st + size - 1
    for i = st, ed do  -- TODO: next server
        local idx = servers[(i - 1) % size + 1]
        if peer_cb(idx, servers[idx]) then
            return servers[idx]
        end
    end

    return nil, "consistent hash: no servers available"
end


function _M.free_consitent_hash_server(srv, failed)
    return
end


return _M
