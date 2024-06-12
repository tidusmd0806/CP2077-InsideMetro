---@class Data
Data = {}
Data.__index = Data

Data.Station = {
    {station = "ARASAKA_WATERFRONT", track_info = {{track = 1, is_final = true, is_invalid = true}, {track = 5, is_final = true, is_invalid = true}}},
    {station = "LITTLE_CHINA_HOSPITAL", track_info = {{track = 1, is_final = false, is_invalid = true}, {track = 5, is_final = false, is_invalid = false}}},
    {station = "LITTLE_CHINA_NORTH", track_info = {{track = 1, is_final = false, is_invalid = true}}},
    {station = "LITTLE_CHINA_SOUTH", track_info = {{track = 4, is_final = false, is_invalid = true}, {track = 5, is_final = false, is_invalid = true}}},
    {station = "JAPAN_TOWN_NORTH", track_info = {{track = 2, is_final = false, is_invalid = false}, {track = 4, is_final = false, is_invalid = false},{track = 5, is_final = false, is_invalid = false}}},
    {station = "JAPAN_TOWN_SOUTH", track_info = {{track = 4, is_final = false, is_invalid = false}, {track = 5, is_final = false, is_invalid = false}}},
    {station = "DOWNTOWN_NORTH", track_info = {{track = 1, is_final = false, is_invalid = false}, {track = 2, is_final = false, is_invalid = false}, {track = 5, is_final = false, is_invalid = false}}},
    {station = "ARROYO", track_info = {{track = 1, is_final = false, is_invalid = false}, {track = 3, is_final = false, is_invalid = false}}},
    {station = "CITY_CENTER", track_info = {{track = 1, is_final = false, is_invalid = false}, {track = 4, is_final = false, is_invalid = false}, {track = 5, is_final = false, is_invalid = false}}},
    {station = "ARASAKA_TOWER", track_info = {{track = 1, is_final = false, is_invalid = false}, {track = 3, is_final = true, is_invalid = false}, {track = 4, is_final = false, is_invalid = false}}},
    {station = "WELLSPRINGS", track_info = {{track = 4, is_final = false, is_invalid = false}, {track = 5, is_final = false, is_invalid = false}}},
    {station = "GLEN_NORTH", track_info = {{track = 2, is_final = false, is_invalid = false}, {track = 4, is_final = false, is_invalid = false}}},
    {station = "GLEN_SOUTH", track_info = {{track = 4, is_final = false, is_invalid = false}, {track = 5, is_final = false, is_invalid = false}}},
    {station = "VISTA_DEL_REY", track_info = {{track = 1, is_final = false, is_invalid = false}, {track = 3, is_final = false, is_invalid = false}, {track = 4, is_final = false, is_invalid = false}, {track = 5, is_final = false, is_invalid = false}}},
    {station = "RANCHO_CORONADO", track_info = {{track = 1, is_final = true, is_invalid = false}, {track = 2, is_final = true, is_invalid = false}}},
    {station = "LITTLE_CHINA_MEGABUILDING", track_info = {{track = 2, is_final = false, is_invalid = true}, {track = 5, is_final = false, is_invalid = true}}},
    {station = "CHARTER_HILL", track_info = {{track = 2, is_final = false, is_invalid = false}, {track = 5, is_final = true, is_invalid = false}}},
    {station = "GLEN_EBUNIKE", track_info = {{track = 2, is_final = false, is_invalid = false}, {track = 4, is_final = false, is_invalid = false}}},
    {station = "PACIFICA_STADIUM", track_info = {{track = 2, is_final = true, is_invalid = false}, {track = 3, is_final = true, is_invalid = false}}},
}

Data.Border = {
    -- {x = -795, y = 1333, z = 87, r = 50, name = "EAST_WATSON"},
    -- {x = -1409, y = 886, z = 48, r = 50, name = "CENTER_WATSON"},
    -- {x = -2085, y = 835, z = 69, r = 50, name = "WEST_WATSON"},
    -- {x = -741, y = -596, z = 37, r = 50, name = "C_LINE_RAINBOW_EAST"},
    -- {x = -1044, y = -376, z = 3, r = 50, name = "C_LINE_RAINBOW_WEST"},
}

return Data