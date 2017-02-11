local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local ok,utils = pcall(require, "common.utils")
if not ok or not utils then
    error("failed to load common.utils:" .. (utils or "nil"))
end

local _M = new_tab(0, 9)
_M._VERSION = '0.1'

_M.DEFAULT_DOMAIN = "s3.amazonaws.com"

_M.CONST = 
{
    SLASH           = "/",
    SLASH_ASCII     = 47,  --ascii code of '/' is 47;
}

_M.AWS_VERSION = 
{
    AWS2 = 2,
    AWS4 = 4,
}

_M.AUTH_METHOD = 
{
    HEADERS = 1,
    QPARAMS = 2,
}

_M.BUCKET_STYLE = 
{
    PATH   = 1,
    HOSTED = 2,
}

_M.PAYLOAD_SHA256_OPT = 
{
    SINGLE_CHUNK_SIGNED   = 1,
    SINGLE_CHUNK_UNSIGNED = 2,
    MULTI_CHUNKS          = 3,
}

_M.SUBRESOURCES = 
{
}

return _M
