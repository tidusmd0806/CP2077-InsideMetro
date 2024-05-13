local Metro = require('Modules/metro.lua')

local Core = {}
Core.__index = Core

function Core:New()
    -- instance --
    local obj = {}
    obj.metro_obj = Metro:New()
    return setmetatable(obj, self)
end

return Core