-- Copyright (C) 2016-2017 Libo Huang (huangnauh), UPYUN Inc.

local _M = {}

_M.global = {
    checkup_timer_interval = 5,
    checkup_timer_overtime = 10,
    checkup_shd_sync_enable = true,
    shd_config_timer_interval = 0.5,
}

_M.shard = {
    mode = "shard",
    slots = 512,
    replicas = 3,

    cluster = {
        {
            servers = {
                { host = "127.0.0.1", port = 12350 },
                { host = "127.0.0.1", port = 12351 },
                { host = "127.0.0.1", port = 12352 },
                { host = "127.0.0.1", port = 12353 },
                { host = "127.0.0.1", port = 12354 },
                { host = "127.0.0.1", port = 12355 },
                { host = "127.0.0.1", port = 12356 },
                { host = "127.0.0.1", port = 12357 },
                { host = "127.0.0.1", port = 12358 },
                { host = "127.0.0.1", port = 12359 },
            }
        },
    },
}

return _M
