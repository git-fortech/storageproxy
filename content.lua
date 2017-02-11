local ok,utils = pcall(require, "common.utils")
if not ok or not utils then
    error("failed to load common.utils:" .. (utils or "nil"))
end

ngx.log(ngx.DEBUG, "ReqID=", ngx.ctx.s3Req.reqid, " ngx.ctx.s3Req=", utils.stringify(ngx.ctx.s3Req))
