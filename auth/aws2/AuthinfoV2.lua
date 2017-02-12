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

    --add subresources and query string parameters overriding response headers
    local params = {"?"}
    local index = 1

    --subresources
    for i,r in ipairs(config.SUB_RESOURCES) do
        if s3Req.httpReq.args[r] == true then
            params[index+1] = r
            params[index+2] = "&" 
            index = index + 2
            s3Req:add_subresource(r, true)
        elseif s3Req.httpReq.args[r] == "" then
            params[index+1] = r .. "="
            params[index+2] = "&" 
            index = index + 2
            s3Req:add_subresource(r, "")
        elseif s3Req.httpReq.args[r] then
            params[index+1] = r .. "=" .. s3Req.httpReq.args[r]
            params[index+2] = "&" 
            index = index + 2
            s3Req:add_subresource(r, s3Req.httpReq.args[r])
        end
    end

    --query string parameters overriding response headers
    for i,r in ipairs(config.OVERRIDING_PARAMS) do
        if s3Req.httpReq.args[r] then
            params[index+1] = r .. "=" .. s3Req.httpReq.args[r]
            params[index+2] = "&" 
            index = index + 2
            s3Req:add_overridingparam(r, s3Req.httpReq.args[r])
        end
    end

    if s3Req.httpReq.method == config.HTTP_METHOD.DELETE then
        local delet_params = s3Req.httpReq.args["delete"] 
        if delet_params then
            params[index+1] = "delete=" .. delet_params
            index = index + 1
        end
    end

    local c = #params
    if c > 1 then  --besides "?", there are more elements
        if params[c] == "&"  then
            table.remove(params, c)
        end
        local params_str = table.concat(params)
        result = result .. params_str
    end

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
