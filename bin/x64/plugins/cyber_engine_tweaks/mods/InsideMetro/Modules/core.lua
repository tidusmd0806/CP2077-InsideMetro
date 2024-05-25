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
    obj.stand_up_anim = "sit_chair_lean0__2h_elbow_on_knees__01__to__stand__2h_on_sides__01__turn0__q005_01__01"
    obj.sit_down_anim = "sit_chair_lean180__2h_on_lap__01"
    obj.ristricted_station_area = {
        -- C Line
        {x = -1322, y = -62, z = -3, r = 50}, -- Memorial Park
        {x = -1114, y = -324, z = -15, r = 50}, -- Congress & MLK
        -- {x = -1478, y = -1893, z = 71, r = 150}, -- Pacifica Stadium
        -- D Line
        -- {x = -1238, y = 19, z = 63, r = 50}, -- Memorial Park
    }
    obj.terminus = {
        -- CD Line
        {x = -1478, y = -1893, z = 71, r = 50}, -- Pacifica Stadium
        -- D Line
        {x = -1238, y = 19, z = 63, r = 50}, -- Memorial Park
    }
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

        local status = self.event_obj:GetStatus()
        if status == Def.State.EnableStand and not self:IsInRestrictedArea() then
            if (action_name == "UETChangePose" and action_type == "BUTTON_PRESSED") or (action_name == "UETWindow" and action_type == "BUTTON_PRESSED") or (action_name == "UETExit" and action_type == "BUTTON_PRESSED") then
                consumer:Consume()
            end
            if action_name == "ChoiceApply" and action_type == "BUTTON_PRESSED" then
                self:EnableWalkingMetro()
            end
        elseif status == Def.State.EnableSit then
            if (action_name == "UETChangePose" and action_type == "BUTTON_PRESSED") or (action_name == "UETWindow" and action_type == "BUTTON_PRESSED") or (action_name == "UETExit" and action_type == "BUTTON_PRESSED") then
                consumer:Consume()
            end
            if action_name == "ChoiceApply" and action_type == "BUTTON_PRESSED" then
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
    local right_dir = self.metro_obj:GetWorldRight()
    local local_workspot_pos = self.metro_obj:GetPlayerSeatPosition()
    local workspot_angle = Vector4.ToRotation(right_dir)
    if self.metro_obj:IsPlayerSeatRightSide() then
        workspot_angle.yaw = workspot_angle.yaw
    else
        workspot_angle.yaw = workspot_angle.yaw + 180
    end
    local world_pos = self.metro_obj:GetAccurateWorldPosition(local_workspot_pos)
    self.player_obj:PlayPose(self.stand_up_anim, world_pos, workspot_angle)
    self:KeepWorkspotSeatPostion(local_workspot_pos, workspot_angle)
    Cron.After(self.wait_time_after_standup, function()
        self.log_obj:Record(LogLevel.Trace, "EnableWalkingMetro: Unmount")
        self.metro_obj:Unmount()
        self.event_obj:SetStatus(Def.State.WalkInsideMetro)
    end)

end

function Core:DisableWalkingMetro()

    self.log_obj:Record(LogLevel.Info, "DisableWalkingMetro")
    self:SetFreezeMode(true)
    Cron.After(0.1, function()
        self.metro_obj:Mount()
        Cron.Every(0.01, {tick = 1}, function(timer)
            if Game.GetPlayer():GetMountedVehicle() == nil then
                self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: Player is in vehicle")
                return
            end
            self.event_obj:SetStatus(Def.State.SitInsideMetro)

            local right_dir = self.metro_obj:GetWorldRight()
            local workspot_pos = self.metro_obj:GetAccurateWorldPosition(self.metro_obj:GetPlayerSeatPosition())
            local workspot_angle = Vector4.ToRotation(right_dir)
            if self.metro_obj:IsPlayerSeatRightSide() then
                workspot_angle.yaw = workspot_angle.yaw
            else
                workspot_angle.yaw = workspot_angle.yaw + 180
            end
            self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: PlayPose")
            self.player_obj:PlayPose(self.sit_down_anim, workspot_pos, workspot_angle)
            Cron.After(0.5, function()
                self:SetFreezeMode(false)
            end)

            Cron.Halt(timer)
        end)
    end)

end

function Core:KeepWorkspotSeatPostion(local_pos, angle)

    Cron.Every(0.01, {tick = 1}, function(timer)
        local workspot_entity = self.player_obj:GetWorkspotEntity()
        if workspot_entity == nil then
            self.log_obj:Record(LogLevel.Trace, "KeepWorkspotSeatPostion: workspot_entity is nil")
            return
        end
        timer.tick = timer.tick + 1
        local world_pos = self.metro_obj:GetAccurateWorldPosition(local_pos)
        if world_pos == nil or angle == nil then
            self.log_obj:Record(LogLevel.Error, "KeepWorkspotSeatPostion: pos or angle is nil")
            Cron.Halt(timer)
            return
        end

        Game.GetTeleportationFacility():Teleport(workspot_entity, world_pos, angle)
        if not self.metro_obj:IsMountedPlayer() then
            self.log_obj:Record(LogLevel.Trace, "DeleteWorkspot")
            self.player_obj:DeleteWorkspot()
            Cron.Halt(timer)
            return
        end
    end)

end

function Core:IsInRestrictedArea()

    local player_pos = Game.GetPlayer():GetWorldPosition()
    for _, area in ipairs(self.ristricted_station_area) do
        local distance = Vector4.Distance(player_pos, Vector4.new(area.x, area.y, area.z, 1))
        if distance < area.r then
            return true
        end
    end
    return false

end

function Core:IsInTerminus()

    local player_pos = Game.GetPlayer():GetWorldPosition()
    for _, area in ipairs(self.terminus) do
        local distance = Vector4.Distance(player_pos, Vector4.new(area.x, area.y, area.z, 1))
        if distance < area.r then
            return true
        end
    end
    return false

end

return Core