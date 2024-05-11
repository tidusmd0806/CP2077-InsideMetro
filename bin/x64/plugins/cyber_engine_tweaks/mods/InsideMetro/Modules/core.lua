local Metro = require('Modules/metro.lua')
local Player = require('Modules/player.lua')

local Core = {}
Core.__index = Core

function Core:New()
    -- instance --
    local obj = {}
    obj.player_obj = Player:New()
    obj.metro_obj = Metro:New(obj.player_obj)
    return setmetatable(obj, self)
end

return Core