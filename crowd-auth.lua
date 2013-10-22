-- string split utility
function split(pString, pPattern)
  local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pPattern
  local last_end = 1

  local s, e, cap = pString:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
       table.insert(Table,cap)
    end

    last_end = e + 1
    s, e, cap = pString:find(fpat, last_end)
  end

  if last_end <= #pString then
    cap = pString:sub(last_end)
    table.insert(Table, cap)
  end

  return Table
end

-- grab auth header
local auth_header = ngx.req.get_headers().authorization

-- check that the header is present, and if not sead authenticate header
if not auth_header or auth_header == '' or not string.match(auth_header, '^[Bb]asic ') then
  ngx.header['WWW-Authenticate'] = 'Basic realm="Git Repositories"'
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

local mime = require 'mime'

-- decode authenication header and verify its good
local userpass = split(mime.unb64(split(auth_header, ' ')[2])..'', ':')
if not userpass or #userpass ~= 2 then
  ngx.exit(ngx.HTTP_BAD_REQUEST)
end

-- define crowd client based off spore json definition
local crowd = require 'Spore'.new_from_string([[{
  "base_url" : "<CROWD_APP_URL>",
  "name" : "crowd",
  "authentication": true,
  "methods": {
    "authentication": {
       "path": "/rest/usermanagement/latest/authentication",
       "method": "POST",
       "required_payload": true,
       "required_params": ["username"],
       "expected_status": [200, 400]
    }
  }
}]])

-- setup crowd client 
crowd:enable('Format.JSON')
crowd:enable('Auth.Basic', {
  username = '<CROWD_APP_NAME>',
  password = '<CROWD_APP_PASS>'
})

-- authenticate against crowd
local res = crowd:authentication({
  username = userpass[1]..'',
  payload = {
    value = userpass[2]..''
  }
})

-- error out if not successful 
if res.status ~= 200 then
  ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- if we've reached here, then the supplied user/pass is good, so set the
-- resulting cwd_user / cwd_email in nginx so it can be used again
ngx.var.cwd_user = res.body.name..''
ngx.var.cwd_email = res.body.email..''
