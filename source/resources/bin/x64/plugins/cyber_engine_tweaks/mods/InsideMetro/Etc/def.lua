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

Def.ChoiceText = {
    Stand = 0,
    Exit = 1
}

-- Inertia system configuration
Def.Inertia = {
    max_velocity_history = 10,          -- Maximum number of velocity history samples
    decay_rate = 0.5,                  -- Inertia decay rate (higher = faster decay)
    metro_velocity_influence = 0.3,     -- Metro velocity influence factor (0-1)
    min_decay_factor = 0.1,            -- Minimum decay factor
    teleport_interval = 0.01           -- Teleport processing interval
}

return Def