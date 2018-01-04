-- Copyright (C) 2016-2017 Libo Huang (huangnauh), UPYUN Inc.

local crc16     = require "resty.checkups.crc16"

local REPLICAS  = 3
local SLOTS     = 512

local _M = { _VERSION = "0.11" }

function _M.shard_idx(shard_key, slots)
    local slots = slots or SLOTS
    return crc16.crc16(shard_key) % slots
end

function _M.next_server(servers, peer_cb, opts)
    local srvs_cnt = #servers
    if srvs_cnt == 1 then
        if peer_cb(1, servers[1]) then
            return servers[1], { backup=false, shard_idx=opts.shard_idx, shard_key=opts.shard_key }
        end

        return nil, nil, "no shard servers available"
    end

    local idx = opts.shard_idx
    local replicas = opts.replicas or REPLICAS

    local backup = false
    for i = 1, replicas do
        local srv = servers[(idx + i - 1) % srvs_cnt + 1]
        if peer_cb(idx, srv) then
            if i > 1 then
                backup = true
            end
            return srv, { backup=backup, shard_idx=idx, shard_key=opts.shard_key }
        end
    end

    return nil, nil, "no shard servers available"
end


function _M.free_server(srv, failed)
end


return _M
