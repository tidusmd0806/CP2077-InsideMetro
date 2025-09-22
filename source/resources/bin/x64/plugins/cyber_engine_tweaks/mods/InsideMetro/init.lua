--------------------------------------------------------
-- CopyRight (C) 2024, tidusmd. All rights reserved.
-- This mod is under the MIT License.
-- https://opensource.org/licenses/mit-license.php
--------------------------------------------------------

Cron = require('External/Cron.lua')
Data = require("Etc/data.lua")
Def = require('Etc/def.lua')
GameHUD = require('External/GameHUD.lua')
GameUI = require('External/GameUI.lua')
Log = require("Etc/log.lua")

local Core = require('Modules/core.lua')
local Debug = require('Debug/debug.lua')

InsideMetro = {
	description = "Inside The Metro",
	version = "1.3.1",
    is_debug_mode = false,
    -- version check
    cet_required_version = 36.0, -- 1.36.0
    cet_version_num = 0,
}

registerForEvent('onInit', function()

    if not InsideMetro:CheckDependencies() then
        print('[ITM][Error] Inside The Metro Mod failed to load due to missing dependencies.')
        return
    end

    InsideMetro.core_obj = Core:New()
    InsideMetro.debug_obj = Debug:New(InsideMetro.core_obj)

    InsideMetro.core_obj:Initialize()

    print('[ITM][Info] Inside The Metro Mod is ready!')

end)

registerForEvent("onDraw", function()
    if InsideMetro.is_debug_mode then
        if InsideMetro.debug_obj ~= nil then
            InsideMetro.debug_obj:ImGuiMain()
        end
    end
end)

registerForEvent('onUpdate', function(delta)
    Cron.Update(delta)
end)

function InsideMetro:CheckDependencies()
    -- Check Cyber Engine Tweaks Version
    local cet_version_str = GetVersion()
    local cet_version_major, cet_version_minor = cet_version_str:match("1.(%d+)%.*(%d*)")
    InsideMetro.cet_version_num = tonumber(cet_version_major .. "." .. cet_version_minor)

    if InsideMetro.cet_version_num < InsideMetro.cet_required_version then
        print("[ITM][Error] Inside The Metro Mod requires Cyber Engine Tweaks version 1." .. InsideMetro.cet_required_version .. " or higher.")
        return false
    end
    return true
end

function InsideMetro:ToggleDebugMode()
    InsideMetro.is_debug_mode = not InsideMetro.is_debug_mode
end

return InsideMetro