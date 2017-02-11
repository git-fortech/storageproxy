local ok,auth = pcall(require, "auth.auth")
if not ok or not auth then
    error("failed to load auth.auth:" .. (auth or "nil"))
end

local passed,errcode = auth.authenticate()

if passed then
    ngx.exit(ngx.OK)     -- goto content phase
else
    ngx.exit(errcode)    -- deny access
end
