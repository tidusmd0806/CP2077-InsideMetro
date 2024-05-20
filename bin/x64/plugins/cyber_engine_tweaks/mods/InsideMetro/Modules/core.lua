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
    obj.wait_time_after_sitdown = 0.01
    obj.seat_forward_offset = 0.8
    obj.sit_position_offset = -0.2
    obj.stand_up_anim = "sit_chair_lean0__2h_elbow_on_knees__01__to__stand__2h_on_sides__01__turn0__q005_01__01"
    obj.sit_down_anim = "sit_chair_lean180__2h_on_lap__01"
    return setmetatable(obj, self)
end

function Core:Initialize()

    self:SetObserverAction()
    self.event_obj:Initialize()

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

        if action_name == "CallVehicle" and action_type == "BUTTON_PRESSED" then
            local status = self.event_obj:GetStatus()
            if status == Def.State.SitInsideMetro then
                self.event_obj:SetStatus(Def.State.StandInsideMetro)
                self:EnableWalkingMetro()
            elseif status == Def.State.StandInsideMetro then
                self:DisableWalkingMetro()
            end
        end
    end)

end

function Core:SetFreezeMode(is_freeze)
    if is_freeze then
        Game.GetTimeSystem():SetTimeDilation(CName.new("pause"), 0.0)
        TimeDilationHelper.SetTimeDilationWithProfile(Game.GetPlayer(), "radialMenu", true, true)
        TimeDilationHelper.SetIgnoreTimeDilationOnLocalPlayerZero(Game.GetPlayer(), true)
    else
        Game.GetTimeSystem():UnsetTimeDilation(CName.new("pause"), "None")
        TimeDilationHelper.SetTimeDilationWithProfile(Game.GetPlayer(), "radialMenu", false, true)
        TimeDilationHelper.SetIgnoreTimeDilationOnLocalPlayerZero(Game.GetPlayer(), false)
    end
end

function Core:EnableWalkingMetro()

    self.log_obj:Record(LogLevel.Info, "EnableWalkingMetro")
    self:SetFreezeMode(true)
    local right_dir = self.metro_obj:GetWorldRight()
    local workspot_pos = self.metro_obj:GetAccurateWorldPosition(self.metro_obj:GetPlayerSeatPosition())
    local workspot_angle = Vector4.ToRotation(right_dir)
    if self.metro_obj:IsPlayerSeatRightSide() then
        workspot_pos.x = workspot_pos.x - right_dir.x * self.seat_forward_offset
        workspot_pos.y = workspot_pos.y - right_dir.y * self.seat_forward_offset
        workspot_pos.z = workspot_pos.z - right_dir.z * self.seat_forward_offset
        workspot_angle.roll = 0
        workspot_angle.pitch = 0
        workspot_angle.yaw = workspot_angle.yaw
    else
        workspot_pos.x = workspot_pos.x + right_dir.x * self.seat_forward_offset
        workspot_pos.y = workspot_pos.y + right_dir.y * self.seat_forward_offset
        workspot_pos.z = workspot_pos.z + right_dir.z * self.seat_forward_offset
        workspot_angle.roll = 0
        workspot_angle.pitch = 0
        workspot_angle.yaw = workspot_angle.yaw * -1
    end
    self.player_obj:PlayPose(self.stand_up_anim, workspot_pos, workspot_angle)
    self:KeepWorkspotSeatPostion()
    Cron.After(0.2, function()
        self:SetFreezeMode(false)
    end)
    Cron.After(self.wait_time_after_standup, function()
        self.log_obj:Record(LogLevel.Trace, "EnableWalkingMetro: Unmount")
        self.metro_obj:Unmount()
    end)

end

function Core:DisableWalkingMetro()

    self.log_obj:Record(LogLevel.Info, "DisableWalkingMetro")
    self.metro_obj:Mount()
    Cron.Every(0.01, {tick = 1}, function(timer)
        if Game.GetPlayer():GetMountedVehicle() == nil then
            self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: Player is in vehicle")
            return
        end
        self.event_obj:SetStatus(Def.State.SitInsideMetro)
        Cron.After(0.2, function()
            self:SetFreezeMode(true)
            local right_dir = self.metro_obj:GetWorldRight()
            local workspot_pos = self.metro_obj:GetAccurateWorldPosition(self.metro_obj:GetPlayerSeatPosition())
            local workspot_angle = Vector4.ToRotation(right_dir)
            if self.metro_obj:IsPlayerSeatRightSide() then
                workspot_pos.x = workspot_pos.x
                workspot_pos.y = workspot_pos.y
                workspot_pos.z = workspot_pos.z + self.sit_position_offset
                workspot_angle.roll = 0
                workspot_angle.pitch = 0
                workspot_angle.yaw = workspot_angle.yaw
            else
                workspot_pos.x = workspot_pos.x
                workspot_pos.y = workspot_pos.y
                workspot_pos.z = workspot_pos.z + self.sit_position_offset
                workspot_angle.roll = 0
                workspot_angle.pitch = 0
                workspot_angle.yaw = workspot_angle.yaw * -1
            end
            self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: PlayPose")
            self.player_obj:PlayPose(self.sit_down_anim, workspot_pos, workspot_angle)
            Cron.After(0.5, function()
                self:SetFreezeMode(false)
            end)
            -- Game.GetTeleportationFacility():Teleport(self.player_obj:GetWorkspotEntity(), workspot_pos, workspot_angle)
        end)
        Cron.Halt(timer)
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
        local pos = self.metro_obj:GetAccurateWorldPosition(self.metro_obj:GetPlayerSeatPosition())
        local angle = Vector4.ToRotation(right_dir)
        if self.metro_obj:IsPlayerSeatRightSide() then
            pos.x = pos.x - right_dir.x * self.seat_forward_offset
            pos.y = pos.y - right_dir.y * self.seat_forward_offset
            pos.z = pos.z - right_dir.z * self.seat_forward_offset
            angle.roll = 0
            angle.pitch = 0
            angle.yaw = angle.yaw
        else
            pos.x = pos.x + right_dir.x * self.seat_forward_offset
            pos.y = pos.y + right_dir.y * self.seat_forward_offset
            pos.z = pos.z + right_dir.z * self.seat_forward_offset
            angle.roll = 0
            angle.pitch = 0
            angle.yaw = angle.yaw * -1
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