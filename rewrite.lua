local ok,uuid = pcall(require, "thirdparty.resty.jit-uuid")
if not ok or not uuid then
    error("failed to load resty.jit-uuid:" .. (uuid or "nil"))
end

local ok,utils = pcall(require, "common.utils")
if not ok or not utils then
    error("failed to load common.utils:" .. (utils or "nil"))
end

local ok,HttpRequest = pcall(require, "http.HttpRequest")
if not ok or not HttpRequest then
    error("failed to load http.HttpRequest:" .. (HttpRequest or "nil"))
end

local ok,S3Request = pcall(require, "s3.S3Request")
if not ok or not S3Request then
    error("failed to load s3.S3Request:" .. (S3Request or "nil"))
end

local ok,ngx_re = pcall(require, "ngx.re")
if not ok or not ngx_re then
    error("failed to load ngx.re:" .. (ngx_re or "nil"))
end

local function build_http_request()
    local method = ngx.var.request_method
    local uri = ngx.var.uri
    local requri = ngx.var.request_uri
    local args = ngx.req.get_uri_args()
    local headers = ngx.req.get_headers()

    return HttpRequest:new(method, uri, requri, args, headers)
end

function build_s3_request(httpReq)
    local reqid = uuid()
    return S3Request:new(reqid, httpReq)
end

local httpReq = build_http_request()
ngx.ctx.s3Req = build_s3_request(httpReq) 
