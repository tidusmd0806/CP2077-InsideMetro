---@class Def
Def = {}
Def.__index = Def

Def.State = {
    OutsideMetro = 0,
    SitInsideMetro = 1,
    EnableStand = 2,
    EnableSit = 3,
    WalkInsideMetro = 4
}

return Def