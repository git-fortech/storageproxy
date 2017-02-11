local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local ok,config = pcall(require, "config")
if not ok or not config then
    error("failed to load config:" .. (config or "nil"))
end

local _M = new_tab(0, 9)
_M._VERSION = '0.1'

function _M.new(self, reqid, httpReq)
    local newobj = 
    {
        reqid      = reqid,
        httpReq    = httpReq,

        buckstyle  = nil,
        bucket     = nil,
        object     = nil,
    }

    local host = httpReq.headers["host"]

    if not host or "" == host or host == config.DEFAULT_DOMAIN then
        newobj.buckstyle = config.BUCKET_STYLE.PATH
    else
        local s,e = ngx.re.find(host, "."..config.DEFAULT_DOMAIN, "jo")

        if not s then
            newobj.buckstyle = config.BUCKET_STYLE.PATH
        else
            --bucket is in "host" header
            newobj.buckstyle = config.BUCKET_STYLE.HOSTED
            newobj.bucket = string.sub(host, 1, s-1)
            newobj.object = string.sub(httpReq.uri, 2, -1)  --remove the leading slash
        end
    end

    if newobj.buckstyle == config.BUCKET_STYLE.PATH then
        local comps, err = ngx.re.match(httpReq.uri, "(\\/)([^\\/]*)([\\/]?)(.*)", "jo")

        newobj.bucket = comps[2]  -- if there is no bucket, buck is ""
        newobj.object = comps[4]  -- if there is no object, obj is ""
    end

    setmetatable(newobj, {__index = self})
    return newobj
end

return _M
