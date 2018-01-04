# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib 'lib';
use Test::Nginx::Socket;
use Cwd qw(cwd);
use Test::Nginx::Socket 'no_plan';

#repeat_each(2);

workers(4);

my $pwd = cwd();

our $HttpConfig = qq{
    lua_socket_log_errors off;
    lua_package_path "$pwd/../lua-resty-lock/?.lua;$pwd/lib/?.lua;$pwd/t/lib/?.lua;;";
    error_log logs/error.log debug;

    lua_shared_dict state 10m;
    lua_shared_dict mutex 1m;
    lua_shared_dict locks 1m;
    lua_shared_dict config 1m;

    server {
        listen 12351;
        location = /status {
            return 200;
        }
    }

    server {
        listen 12352;
        location = /status {
            return 200;
        }
    }

    server {
        listen 12353;
        location = /status {
            return 200;
        }
    }

    server {
        listen 12354;
        location = /status {
            return 200;
        }
    }

    server {
        listen 12355;
        location = /status {
            return 200;
        }
    }

    server {
        listen 12356;
        location = /status {
            return 200;
        }
    }

    server {
        listen 12357;
        location = /status {
            return 200;
        }
    }

    server {
        listen 12358;
        location = /status {
            return 404;
        }
    }

    server {
        listen 12359;
        location = /status {
            return 502;
        }
    }

    server {
        listen 12350;
        location = /status {
            return 404;
        }
    }

    init_by_lua '
        local config = require "config_shard"
        local checkups = require "resty.checkups"
        checkups.init(config)
    ';

    init_worker_by_lua '
        local config = require "config_shard"
        local checkups = require "resty.checkups"
        checkups.prepare_checker(config)
        checkups.create_checker()
    ';

};

$ENV{TEST_NGINX_CHECK_LEAK} = 1;
$ENV{TEST_NGINX_USE_HUP} = 1;
$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
#no_diff();
no_long_string();

run_tests();

__DATA__

=== TEST 1: shard ready_ok
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        access_log off;
        content_by_lua '
            local checkups = require "resty.checkups"
            ngx.sleep(1)
            local cb_ok = function(host, port)
                ngx.say(host .. ":" .. port)
                return 1
            end

            local ok, err = checkups.ready_ok("shard", cb_ok, {shard_key = "usage-test/test.dmg"})
            local ok, err = checkups.ready_ok("shard", cb_ok, {shard_key = "usage-test/test.dmg"})
            local ok, err = checkups.ready_ok("shard", cb_ok, {shard_key = "usage-test/README.md"})
            local ok, err = checkups.ready_ok("shard", cb_ok, {shard_key = "usage-test/README.md"})
        ';
    }
--- request
GET /t
--- response_body
127.0.0.1:12358
127.0.0.1:12358
127.0.0.1:12352
127.0.0.1:12352


=== TEST 2: shard_idx
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        access_log off;
        content_by_lua '
            local shard = require "resty.checkups.shard"

            ngx.say(shard.shard_idx("usage-test/test.dmg", 512))
            ngx.say(shard.shard_idx("usage-test/test.dmg", 512))
            ngx.say(shard.shard_idx("usage-test/README.md", 512))
            ngx.say(shard.shard_idx("usage-test/README.md", 512))
            ngx.say(shard.shard_idx("usage-test/sfdsdf我", 512))
            ngx.say(shard.shard_idx("usage-test/sfdsdf我", 512))
        ';
    }
--- request
GET /t
--- response_body
278
278
32
32
143
143
