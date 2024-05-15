local Metro = require('Modules/metro.lua')
local Player = require('Modules/player.lua')

local Core = {}
Core.__index = Core

function Core:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Core")
    obj.player_obj = Player:New()
    obj.metro_obj = Metro:New()
    -- static --
    obj.despawn_count_after_standup = 250
    obj.wait_time_after_standup = 2.0
    obj.wait_time_after_sitdown = 0.1
    obj.stand_up_anim = "sit_chair_lean0__2h_elbow_on_knees__01__to__stand__2h_on_sides__01__turn0__q005_01__01"
    -- obj.stand_up_anim = "sit_chair_lean180__2h_on_lap__01"
    obj.sit_down_anim = "sit_chair_lean180__2h_on_lap__01"
    return setmetatable(obj, self)
end

function Core:Init()

    self.metro_obj:Init()

end

function Core:EnableWalkingMetro()

    self.log_obj:Record(LogLevel.Info, "EnableWalkingMetro")
    self.player_obj:PlayPose(self.stand_up_anim)
    self:KeepWorkspotRelativePostion()
    Cron.After(self.wait_time_after_standup, function()
        self.log_obj:Record(LogLevel.Trace, "EnableWalkingMetro: Unmount")
        self.metro_obj:Unmount()
    end)

end

function Core:DisableWalkingMetro()

    self.log_obj:Record(LogLevel.Info, "DisableWalkingMetro")
    self.metro_obj:Mount()
    Cron.After(self.wait_time_after_sitdown, function()
        self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: PlayPose")
        self.player_obj:PlayPose(self.sit_down_anim)
    end)

end

function Core:KeepWorkspotRelativePostion()

    Cron.Every(0.01, {tick = 1}, function(timer)
        local workspot_entity = self.player_obj:GetWorkspotEntity()
        if workspot_entity == nil then
            self.log_obj:Record(LogLevel.Trace, "KeepWorkspotRelativePostion: workspot_entity is nil")
            return
        end
        timer.tick = timer.tick + 1
        local pos = self.metro_obj:GetWorldPosition()
        local angle = self.metro_obj:GetWorldOrientation():ToEulerAngles()
        if pos == nil or angle == nil then
            self.log_obj:Record(LogLevel.Error, "KeepWorkspotRelativePostion: pos or angle is nil")
            Cron.Halt(timer)
            return
        end
        Game.GetTeleportationFacility():Teleport(workspot_entity, pos, angle)
        if not self.metro_obj:IsMountedPlayer() then
            self.log_obj:Record(LogLevel.Trace, "DeleteWorkspot")
            self.player_obj:DeleteWorkspot()
            Cron.Halt(timer)
            return
        end
    end)

end

return Core