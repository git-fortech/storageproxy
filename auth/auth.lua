local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local ok,config = pcall(require, "config")
if not ok or not config then
    error("failed to load config:" .. (config or "nil"))
end

local ok,AuthinfoV2 = pcall(require, "auth.aws2.AuthinfoV2")
if not ok or not AuthinfoV2 then
    error("failed to load auth.aws2.AuthinfoV2:" .. (AuthinfoV2 or "nil"))
end

local ok,AuthinfoV4 = pcall(require, "auth.aws4.AuthinfoV4")
if not ok or not AuthinfoV4 then
    error("failed to load auth.aws4.AuthinfoV4:" .. (AuthinfoV4 or "nil"))
end

local ok,utils = pcall(require, "common.utils")
if not ok or not utils then
    error("failed to load common.utils:" .. (utils or "nil"))
end

local _M = new_tab(0, 9)
_M._VERSION = '0.1'

--return: authinfo, errcode
local function parse_authinfo(s3Req)

    local httpReq = s3Req.httpReq

    ----------------------------------------------------------------------------------------------------
    -- Trying Authorization headers --------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    local authmeth = config.AUTH_METHOD.HEADERS

    local authHeader = httpReq.headers["Authorization"]
    if authHeader and "" ~= authHeader then
        local cp, err = ngx.re.match(authHeader, "^AWS\\s+([0-9A-Za-z]+)\\s*:\\s*(\\S+)", "jo")
        if err then
            ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " ngx regular expression error")
            return nil, 500
        end

        local accessidV2   = cp and cp[1]
        local secretKeyV2  = cp and cp[2] 

        if accessidV2 and secretKeyV2 then
            local authinfo = AuthinfoV2:new(authmeth, accessidV2, secretKeyV2, nil)
            return authinfo
        end

        local cp, err = ngx.re.match(authHeader, "^AWS4-HMAC-SHA256\\sCredential=([0-9A-Z]+)\\/(\\d{8})\\/(\\S+)\\/(\\S+)\\/aws4_request,SignedHeaders=(\\S+),Signature=([a-f0-9]+)", "jo")
        if err then
            ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " ngx regular expression error")
            return nil, 500
        end

        local accessidV4          = cp and cp[1]
        local dateV4              = cp and cp[2]
        local regionV4            = cp and cp[3]
        local serviceV4           = cp and cp[4]
        local signedheadersV4     = cp and cp[5]
        local signatureV4         = cp and cp[6]
        local expiresV4           = nil
        local dtimeV4             = nil

        if accessidV4 and dateV4 and regionV4 and serviceV4 and signedheadersV4 and signatureV4 then
            local authinfo = AuthinfoV4:new(authmeth, accessidV4, dateV4, regionV4, serviceV4, signatureV4, expiresV4, dtimeV4, signedheadersV4, s3Req)
            return authinfo
        end

        ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " invalid authorization header")
        return nil, 400
    end

    ----------------------------------------------------------------------------------------------------
    -- Trying Query Parameters -------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    local authmeth = config.AUTH_METHOD.QPARAMS

    local accV2 = httpReq.args["AWSAccessKeyId"]
    local sigV2 = httpReq.args["Signature"]
    local expV2 = httpReq.args["Expires"]

    local accessidV2   = httpReq.args["AWSAccessKeyId"]
    local secretKeyV2  = httpReq.args["Signature"]
    local expiresV2    = httpReq.args["Expires"]

    if accessidV2 and secretKeyV2 then
        local authinfo = AuthinfoV2:new(authmeth, accessidV2, secretKeyV2, expiresV2)
        return authinfo
    end

    local algV4 = httpReq.args["X-Amz-Algorithm"]
    if "AWS4-HMAC-SHA256" == algV4 then
        local credential  = httpReq.args["X-Amz-Credential"]

        local signedheadersV4     = httpReq.args["X-Amz-SignedHeaders"]
        local signatureV4         = httpReq.args["X-Amz-Signature"]
        local expiresV4           = httpReq.args["X-Amz-Expires"]
        local dtimeV4             = httpReq.args["X-Amz-Date"]

        if not credential or not signatureV4 or not signedheadersV4 then
            ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " invalid request, required headers are missing for AWS4")
            return nil, 400
        end

        local cp, err = ngx.re.match(credential, "([0-9A-Z]+)\\/(\\d{8})\\/(\\S+)\\/(\\S+)\\/aws4_request", "jo")
        if err then
            ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " ngx regular expression error")
            return nil, 500
        end

        local accessidV4          = cp and cp[1] 
        local dateV4              = cp and cp[2] 
        local regionV4            = cp and cp[3] 
        local serviceV4           = cp and cp[4] 

        if not accessidV4 or not dateV4 or not regionV4 or not serviceV4 then
            ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " invalid request, credential is malformated for AWS4")
            return nil, 400
        end

        local authinfo = AuthinfoV4:new(authmeth, accessidV4, dateV4, regionV4, serviceV4, signatureV4, expiresV4, dtimeV4, signedheadersV4, s3Req)
        return authinfo
    end

    ----------------------------------------------------------------------------------------------------
    -- Trying Browser-Based Uploads Using POST ---------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    -- TODO:


    ----------------------------------------------------------------------------------------------------
    -- all tries have failed ---------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " invalid request, no authorization info found")
    return nil, 400
end

--return: passed, errcode
local function do_authenticate(authinfo, s3Req)
    local sig_original   = authinfo:get_original_sig()
    local sig_calculated = authinfo:get_calculated_sig(s3Req)

    ngx.log(ngx.DEBUG, "ReqID=", s3Req.reqid, " sig_original   = ", sig_original)
    ngx.log(ngx.DEBUG, "ReqID=", s3Req.reqid, " sig_calculated = ", sig_calculated)

    --[[
    if sig_original ~= sig_calculated then
        return false, ngx.HTTP_FORBIDDEN 
    end
    --]]

    return true
end

--return: passed, errcode
function _M.authenticate()
    local s3Req = ngx.ctx.s3Req

    local authinfo,errcode = parse_authinfo(s3Req)

    if not authinfo then
        return false, errcode 
    end

    return do_authenticate(authinfo, s3Req)
end

return _M
