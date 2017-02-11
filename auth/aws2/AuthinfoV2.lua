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

function _M.new(self, auth_method, accessid, signature, expires)
    local newobj = 
    {
        aws          = config.AWS_VERSION.AWS2,
        authmeth     = auth_method,
        accessid     = accessid,
        signature    = signature,
        expires      = expires,
    }

    setmetatable(newobj, {__index = self})
    return newobj
end

local function get_canonicalized_resource(self, s3Req)
    local result = nil 
    if s3Req.buckstyle == config.BUCKET_STYLE.HOSTED then
        result = config.CONST.SLASH .. s3Req.bucket
    else
        result = ""
    end

    result = result .. s3Req.httpReq.uri

    ngx.log(ngx.DEBUG, "ReqID=", s3Req.reqid, " canonicalized_resource=", result)

    return result
end

function _M.get_original_sig(self)
    return self.signature
end

function _M.get_calculated_sig(self, s3Req)
    local canon_res = get_canonicalized_resource(self, s3Req)
    return canon_res
end

return _M
