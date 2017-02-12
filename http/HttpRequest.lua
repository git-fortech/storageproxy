local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 9)
_M._VERSION = '0.1'

function _M.new(self, method, uri, requri, args, headers)
    local newobj = 
    {
        method       = method,
        uri          = uri,
        req_uri      = requri,
        args         = args,
        headers      = headers,
        bodyreader   = nil,
    }

    setmetatable(newobj, {__index = self})
    return newobj
end

return _M
