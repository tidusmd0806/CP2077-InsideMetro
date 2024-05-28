---@class Def
Def = {}
Def.__index = Def

Def.State = {
    Invalid = -1,
    OutsideMetro = 0,
    SitInsideMetro = 1,
    EnableStand = 2,
    EnableSit = 3,
    WalkInsideMetro = 4
}

Def.ChoiceVariation = {
    Stand = 0,
    Sit = 1
}

return Def