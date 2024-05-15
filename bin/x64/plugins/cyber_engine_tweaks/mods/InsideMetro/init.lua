--------------------------------------------------------
-- CopyRight (C) 2024, tidusmd. All rights reserved.
-- This mod is under the MIT License.
-- https://opensource.org/licenses/mit-license.php
--------------------------------------------------------

Cron = require('External/Cron.lua')
Log = require("Tools/log.lua")

local Core = require('Modules/core.lua')
local Debug = require('Debug/debug.lua')

ITM = {
	description = "Inside The Metro",
	version = "0.1.0",
    is_debug_mode = true,
    -- version check
    cet_required_version = 32.2, -- 1.32.2
    cet_recommended_version = 32.2, -- 1.32.2
    cet_version_num = 0,
}

registerForEvent('onInit', function()

    if not ITM:CheckDependencies() then
        print('[Error] Inside The Metro Mod failed to load due to missing dependencies.')
        return
    end

    ITM.core_obj = Core:New()
    ITM.debug_obj = Debug:New(ITM.core_obj)

    print('Inside The Metro Mod is ready!')

end)

registerForEvent("onDraw", function()
    if ITM.is_debug_mode then
        if ITM.debug_obj ~= nil then
            ITM.debug_obj:ImGuiMain()
        end
    end
end)

registerForEvent('onUpdate', function(delta)
    Cron.Update(delta)
end)

function ITM:CheckDependencies()

    -- Check Cyber Engine Tweaks Version
    local cet_version_str = GetVersion()
    local cet_version_major, cet_version_minor = cet_version_str:match("1.(%d+)%.*(%d*)")
    ITM.cet_version_num = tonumber(cet_version_major .. "." .. cet_version_minor)

    if ITM.cet_version_num < ITM.cet_required_version then
        print("Inside The Metro Mod requires Cyber Engine Tweaks version 1." .. ITM.cet_required_version .. " or higher.")
        return false
    end

    return true

end

return ITM