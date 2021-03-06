# About #
This repository contains a simple [Atlassian Crowd](https://www.atlassian.com/software/crowd) authentication script for [nginx](http://nginx.org/), written
in [Lua](http://www.lua.org/), for use with the [access_by_lua_file](https://github.com/chaoslawful/lua-nginx-module#access_by_lua_file) directive.

This is used in production on Debian 7.2, running the latest
[dotdeb](http://www.dotdeb.org) nginx packages. An attempt was made to use as
much "off-the-shelf" packaging as possible. This script relies
on the use of [lua-Spore](http://fperrad.github.io/lua-Spore/) REST
client/library.

Please note there is an actual nginx module available that can accomplish the
same, however it requires building your own packages. It is available
[here](https://github.com/kare/ngx_http_auth_crowd_module). I am making this
available as, in all things, it is preferrable (for me, at any rate), to use
packages when available over building packages or compiling software directly.

Also, please see the related [JIRA Issue](https://jira.atlassian.com/browse/CWD-2754).

## Installation and Configuration ##

- Install related packages for Lua and lua-Spore dependency:

```
aptitude install lua5.1 luarocks
luarocks install luasec
luarocks install lua-spore
```

- Copy the `crowd-auth.lua` to somewhere accessible by nginx:

```
mkdir -p /etc/nginx/lua && cp crowd-auth.lua /etc/nginx/lua
```

- [Add a new application in
  Crowd](https://confluence.atlassian.com/display/CROWD/Adding+an+Application),
  and test the connectivity with the users/groups you wish to authenticate
  with.

- Modify the `crowd-auth.lua`, replacing `<CROWD_APP_URL>`, `<CROWD_APP_NAME>`,
  `<CROWD_APP_PASS>` with the Crowd base url, the application name and the
  application password created in the previous step.

- Add a `access_by_lua_file` directive in a nginx site stanza, similar to the following:

```
server {
  listen 80;

  server_name host.example.com;
  root /var/www/host.example.com;

  location ~ ^/protected/ {
    set $cwd_user 'unknown';
    set $cwd_email 'unknown@unknown.com';

    access_by_lua_file /etc/nginx/lua/crowd-auth.lua;

    fastcgi_param REMOTE_USER $cwd_user;
  }
}
```

## Authenticating against Atlassian JIRA or other REST-enabled App ##
While untried, modifying this script for use authenticating against
[Atlassian JIRA](https://www.atlassian.com/software/jira) (or other app) should be fairly
straight forward, as JIRA's REST API is very similar (if not identical) to
Crowd's. Should you do that, please email me and/or provide a pull request and
I will gladly integrate the changes within this repository.

Similarly, should you find this useful in negotiating authentication against
any other apps, please let me know via email, and/or provide a pull request, so
that fellow devops teams do not need to continously reinvent the wheel ;).
