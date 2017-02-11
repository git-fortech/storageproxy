local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local ok,config = pcall(require, "config")
if not ok or not config then
    error("failed to load config:" .. (config or "nil"))
end

local ok,ngx_re = pcall(require, "ngx.re")
if not ok or not ngx_re then
    error("failed to load ngx.re:" .. (ngx_re or "nil"))
end

local _M = new_tab(0, 9)
_M._VERSION = '0.1'


local function get_canonical_uri()
    local canon_uri = new_tab(256, 0)
    local index = 1
end


function _M.new(self, auth_method, accessid, date, region, service, signature, expires, dtime, signed_headers, s3Req)
    local newobj = 
    {
        aws          = config.AWS_VERSION.AWS4,
        authmeth     = auth_method,
        accessid     = accessid,
        date         = date,
        region       = region,
        service      = service,
        signature    = signature,
        expires      = expires,
        dtime        = dtime,     --UTC time, in the "yyyyMMddTHHmmssZ" format

        sheaders        = nil,
        reqmethod       = s3Req.httpReq.method,
        pl_sha256_opt   = nil,
        pl_sha256       = nil,
    }

    -- Parse signed_headers
    local shs,err = nil,nil

    if newobj.authmeth == config.AUTH_METHOD.HEADERS then
        shs,err = ngx_re.split(signed_headers, ";")
    elseif newobj.authmeth == config.AUTH_METHOD.QPARAMS then
        shs,err = ngx_re.split(signed_headers, ",")
    else
        ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " invalid authmeth:", newobj.authmeth)
        assert(false)  -- Bad request
    end

    if not shs or err then
        ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " ngx_re error. authmeth=", newobj.authmeth)
        return nil
    end

    newobj.sheaders = shs


    -- Parse payload transfer options. there are 3 options:
    --   a. single chunk, payload is signed. in this case, header x-amz-content-sha256 = payload checksum;
    --   b. single chunk, payload is unsigned. in this case, header x-amz-content-sha256 = UNSIGNED-PAYLOAD; 
    --   c. multiple chunks. in this case, header x-amz-content-sha256 = STREAMING-AWS4-HMAC-SHA256-PAYLOAD;
    local sha256 = s3Req.httpReq.headers["x-amz-content-sha256"]
    if not sha256 then
        ngx.log(ngx.ERR, "ReqID=", s3Req.reqid, " header x-amz-content-sha256 is missing")
        assert(false)  -- Bad request
    end

    if sha256 == "UNSIGNED-PAYLOAD" then
        newobj.pl_sha256_opt = config.PAYLOAD_SHA256_OPT.SINGLE_CHUNK_UNSIGNED
    elseif sha256 == "STREAMING-AWS4-HMAC-SHA256-PAYLOAD" then
        newobj.pl_sha256_opt = config.PAYLOAD_SHA256_OPT.MULTI_CHUNKS
    else
        newobj.pl_sha256_opt = config.PAYLOAD_SHA256_OPT.SINGLE_CHUNK_SIGNED
    end
    newobj.pl_sha256 = sha256

    setmetatable(newobj, {__index = self})
    return newobj
end

local function get_canonical_request(self)
    -- "GET|PUT|POST"         + "\n" +
    -- Canonical URI          + "\n" +
    -- Canonical QueryString  + "\n" +
    -- Canonical Headers      + "\n" +
    -- Signed Headers         + "\n" +
    -- Hashed Payload
    
    local canon_req = self.reqmethod .. "\n"
end

local function get_string_to_sign(self)
end

local function get_signing_key(self)
end

function _M.get_original_sig(self)
    return self.signature
end

function _M.get_calculated_sig(self, s3Req)
    return "ABCD"
end


return _M
