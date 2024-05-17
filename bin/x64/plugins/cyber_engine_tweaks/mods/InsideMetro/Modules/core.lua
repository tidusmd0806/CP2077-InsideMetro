local Event = require('Modules/event.lua')
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
    obj.event_obj = Event:New(obj.player_obj, obj.metro_obj)
    -- static --
    obj.event_check_interval = 0.01
    obj.despawn_count_after_standup = 250
    obj.wait_time_after_standup = 3.5
    obj.wait_time_after_sitdown = 0.1
    obj.seat_forward_offset = 0.3
    obj.stand_up_anim = "sit_chair_lean0__2h_elbow_on_knees__01__to__stand__2h_on_sides__01__turn0__q005_01__01"
    -- obj.stand_up_anim = "sit_chair_lean180__2h_on_lap__01"
    obj.sit_down_anim = "sit_chair_lean180__2h_on_lap__01"
    return setmetatable(obj, self)
end

function Core:Init()

    self:SetObserverAction()
    self.event_obj:SetObserverGameUI()

    Cron.Every(self.event_check_interval, {tick = 1}, function(timer)
        self.event_obj:CheckAllEvents()
    end)

end

function Core:SetObserverAction()

    Observe("PlayerPuppet", "OnAction", function(this, action, consumer)
        local action_name = action:GetName(action).value
		local action_type = action:GetType(action).value
        local action_value = action:GetValue(action)

        self.log_obj:Record(LogLevel.Debug, "Action Name: " .. action_name .. " Type: " .. action_type .. " Value: " .. action_value)

        if self.event_obj.current_status == Def.State.SitInsideMetro then
            if action_name == "CallVehicle" and action_type == "BUTTON_PRESSED" then
                self:EnableWalkingMetro()
                self.event_obj:SetStatus(Def.State.StandInsideMetro)
            end
        end
    end)

end

function Core:EnableWalkingMetro()

    self.log_obj:Record(LogLevel.Info, "EnableWalkingMetro")
    local right_dir = self.metro_obj:GetWorldRight()
    local workspot_pos = self.metro_obj:ChangeWorldPosition(self.metro_obj:GetPlayerSeatPosition())
    local workspot_angle = Vector4.ToRotation(right_dir)
    if self.metro_obj:IsPlayerSeatRightSide() then
        workspot_pos.x = workspot_pos.x - right_dir.x * self.seat_forward_offset
        workspot_pos.y = workspot_pos.y - right_dir.y * self.seat_forward_offset
        workspot_angle.roll = 0
        workspot_angle.pitch = 0
        workspot_angle.yaw = workspot_angle.yaw + Pi()
    else
        workspot_pos.x = workspot_pos.x + right_dir.x
        workspot_pos.y = workspot_pos.y + right_dir.y
        workspot_angle.roll = 0
        workspot_angle.pitch = 0
        workspot_angle.yaw = workspot_angle.yaw
    end
    self.player_obj:PlayPose(self.stand_up_anim, workspot_pos, workspot_angle)
    self:KeepWorkspotSeatPostion()
    Cron.After(self.wait_time_after_standup, function()
        self.log_obj:Record(LogLevel.Trace, "EnableWalkingMetro: Unmount")
        self.metro_obj:Unmount()
    end)

end

function Core:DisableWalkingMetro()

    self.log_obj:Record(LogLevel.Info, "DisableWalkingMetro")
    self.metro_obj:Mount()
    local right_dir = self.metro_obj:GetWorldRight()
    local workspot_pos = Game.GetPlayer():GetWorldPosition()
    local workspot_angle = Vector4.ToRotation(right_dir)
    if self.metro_obj:IsPlayerSeatRightSide() then
        workspot_pos.x = workspot_pos.x - right_dir.x * self.seat_forward_offset
        workspot_pos.y = workspot_pos.y - right_dir.y * self.seat_forward_offset
        workspot_angle.roll = 0
        workspot_angle.pitch = 0
        workspot_angle.yaw = workspot_angle.yaw + Pi()
    else
        workspot_pos.x = workspot_pos.x + right_dir.x * self.seat_forward_offset
        workspot_pos.y = workspot_pos.y + right_dir.y * self.seat_forward_offset
        workspot_angle.roll = 0
        workspot_angle.pitch = 0
        workspot_angle.yaw = workspot_angle.yaw
    end
    Cron.After(self.wait_time_after_sitdown, function()
        self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: PlayPose")
        self.player_obj:PlayPose(self.sit_down_anim, workspot_pos, workspot_angle)
    end)

end

function Core:KeepWorkspotSeatPostion()

    Cron.Every(0.01, {tick = 1}, function(timer)
        local workspot_entity = self.player_obj:GetWorkspotEntity()
        if workspot_entity == nil then
            self.log_obj:Record(LogLevel.Trace, "KeepWorkspotSeatPostion: workspot_entity is nil")
            return
        end
        timer.tick = timer.tick + 1
        local right_dir = self.metro_obj:GetWorldRight()
        local pos = self.metro_obj:ChangeWorldPosition(self.metro_obj:GetPlayerSeatPosition())
        local angle = Vector4.ToRotation(right_dir)
        if self.metro_obj:IsPlayerSeatRightSide() then
            pos.x = pos.x - right_dir.x * self.seat_forward_offset
            pos.y = pos.y - right_dir.y * self.seat_forward_offset
            angle.roll = 0
            angle.pitch = 0
            angle.yaw = angle.yaw + Pi()
        else
            pos.x = pos.x + right_dir.x * self.seat_forward_offset
            pos.y = pos.y + right_dir.y * self.seat_forward_offset
            angle.roll = 0
            angle.pitch = 0
            angle.yaw = angle.yaw
        end
        if pos == nil or angle == nil then
            self.log_obj:Record(LogLevel.Error, "KeepWorkspotSeatPostion: pos or angle is nil")
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