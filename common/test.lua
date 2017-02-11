package.path="./?.lua;;"  

local utils = require "utils"

local v1 = nil
local v2 = true 
local v3 = false
local v4 = 3.1415
local v5 = "abcd"
local v6 = string.rep("ABCD", 100)
local v7 = function() return true end
local v8 = coroutine.create(function() return true end)
--local v9 = ngx.null
local v10 = {}
local v11 = {v1,v2,v3,v4,v5,v6,v7,v8,v9,v10}
local v12 = {
    ["key1"] = nil,
    ["key2"] = true,
    ["key3"] = false,
}
v12.key4 = v11

print(utils.stringify(v1))
print(utils.stringify(v2))
print(utils.stringify(v3))
print(utils.stringify(v4))
print(utils.stringify(v5))
print(utils.stringify(v6))
print(utils.stringify(v7))
print(utils.stringify(v8))
print(utils.stringify(v9))
print(utils.stringify(v10))
print(utils.stringify(v11))
print(utils.stringify(v12))
