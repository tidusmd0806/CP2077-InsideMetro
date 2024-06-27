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
    obj.wait_time_after_standup = 3.5
    obj.stand_up_anim = "sit_chair_lean0__2h_elbow_on_knees__01__to__stand__2h_on_sides__01__turn0__q005_01__01"
    obj.sit_down_anim = "sit_chair_lean180__2h_on_lap__01"
    -- dynamic --
    obj.move_forward = false
    obj.move_backward = false
    obj.move_right = false
    obj.move_left = false
    obj.move_yaw = 0
    obj.is_locked_apply_action = false
    return setmetatable(obj, self)
end

function Core:Initialize()

    self.event_obj:Initialize()
    self:SetObserverAction()

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

        if self.event_obj:IsInPouse() then
            return
        end
        local status = self.event_obj:GetStatus()
        if status == Def.State.EnableStand and not self.metro_obj:IsCurrentInvalidStation() then
            if (action_name == "UETChangePose" and action_type == "BUTTON_PRESSED") or (action_name == "UETWindow" and action_type == "BUTTON_PRESSED") then
                consumer:Consume()
                return
            end
            if action_name == "UETExit" and action_type == "BUTTON_PRESSED" then
                -- if self.event_obj.hud_obj.selected_choice_index ~= Def.ChoiceText.Exit then
                    -- consumer:Consume()
                -- end
                if self.is_locked_apply_action then
                    consumer:Consume()
                end
                self.is_locked_apply_action = true
                Cron.After(5.5, function()
                    self.is_locked_apply_action = false
                end)
            end
            if action_name == "ChoiceApply" and action_type == "BUTTON_PRESSED" then
                if self.event_obj.hud_obj.selected_choice_index == Def.ChoiceText.Stand then
                    if self.is_locked_apply_action then
                        return
                    end
                    self.is_locked_apply_action = true
                    self:EnableWalkingMetro()
                    Cron.After(5.5, function()
                        self.is_locked_apply_action = false
                    end)
                end
            elseif action_name == "ChoiceScrollUp" and action_type == "BUTTON_PRESSED" then
                if self.is_locked_apply_action then
                    return
                end
                self.is_locked_apply_action = true
                self.event_obj.hud_obj:HideChoice()
                if self.event_obj.hud_obj.selected_choice_index >= self.event_obj.hud_obj.max_stand_choice_num then
                    self.event_obj.hud_obj.selected_choice_index = 0
                else
                    self.event_obj.hud_obj.selected_choice_index = self.event_obj.hud_obj.selected_choice_index + 1
                end
                self.event_obj.hud_obj:ShowChoice(Def.ChoiceVariation.Stand)
                Cron.After(0.5, function()
                    self.is_locked_apply_action = false
                end)
            elseif action_name == "ChoiceScrollDown" and action_type == "BUTTON_PRESSED" then
                if self.is_locked_apply_action then
                    return
                end
                self.is_locked_apply_action = true
                self.event_obj.hud_obj:HideChoice()
                if self.event_obj.hud_obj.selected_choice_index <= 0 then
                    self.event_obj.hud_obj.selected_choice_index = self.event_obj.hud_obj.max_stand_choice_num - 1
                else
                    self.event_obj.hud_obj.selected_choice_index = self.event_obj.hud_obj.selected_choice_index - 1
                end
                self.event_obj.hud_obj:ShowChoice(Def.ChoiceVariation.Stand)
                Cron.After(0.5, function()
                    self.is_locked_apply_action = false
                end)
            end
        elseif status == Def.State.EnableSit then
            if (action_name == "UETChangePose" and action_type == "BUTTON_PRESSED") or (action_name == "UETWindow" and action_type == "BUTTON_PRESSED") or (action_name == "UETExit" and action_type == "BUTTON_PRESSED") then
                consumer:Consume()
            end
            if action_name == "ChoiceApply" and action_type == "BUTTON_PRESSED" then
                self:DisableWalkingMetro()
            end
        end

        -- refer to free fly mod (https://www.nexusmods.com/cyberpunk2077/mods/780)
        if action_name == 'Forward' then
            if action_type == 'BUTTON_PRESSED' then
                self.move_forward = true
            elseif action_type == 'BUTTON_RELEASED' then
                self.move_forward = false
            end
        elseif action_name == 'Back' then
            if action_type == 'BUTTON_PRESSED' then
                self.move_backward = true
            elseif action_type == 'BUTTON_RELEASED' then
                self.move_backward = false
            end
        elseif action_name == 'Right' then
            if action_type == 'BUTTON_PRESSED' then
                self.move_right = true
            elseif action_type == 'BUTTON_RELEASED' then
                self.move_right = false
            end
        elseif action_name == 'Left' then
            if action_type == 'BUTTON_PRESSED' then
                self.move_left = true
            elseif action_type == 'BUTTON_RELEASED' then
                self.move_left = false
            end
        elseif action_name == "MoveX" then
            if action_value < 0 then
                self.move_right = false
                self.move_left = true
            else
                self.move_right = true
                self.move_left = false
            end
            if action_value == 0 then
                self.move_right = false
                self.move_left = false
            end
        elseif action_name == "MoveY" then
            if action_value < 0 then
                self.move_forward = false
                self.move_backward = true
            else
                self.move_forward = true
                self.move_backward = false
            end
            if action_value == 0 then
                self.move_forward = false
                self.move_backward = false
            end
        elseif action_name == "CameraMouseX" then
            local sens = Game.GetSettingsSystem():GetVar("/controls/fppcameramouse", "FPP_MouseX"):GetValue() / 2.9
            self.move_yaw = - (action_value / 35) * sens
        elseif action_name == "right_stick_x" then
            local x = action:GetValue(action)
            local sens = Game.GetSettingsSystem():GetVar("/controls/fppcamerapad", "FPP_PadX"):GetValue() / 10
            self.move_yaw = - x * 1.7 * sens
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

    if self.is_switching_pose then
        return
    end
    self.is_switching_pose = true

    self.log_obj:Record(LogLevel.Info, "EnableWalkingMetro")
    local right_dir = self.metro_obj:GetWorldRight()
    local local_workspot_pos = self.metro_obj:GetPlayerSeatPosition()
    local workspot_angle = Vector4.ToRotation(right_dir)
    if self.metro_obj:IsPlayerSeatRightSide() then
        workspot_angle.yaw = workspot_angle.yaw
    else
        workspot_angle.yaw = workspot_angle.yaw + 180
    end
    local_workspot_pos.y = local_workspot_pos.y + self.event_obj.standing_y_offset
    local world_pos = self.metro_obj:GetAccurateWorldPosition(local_workspot_pos)
    self.player_obj:PlayPose(self.stand_up_anim, world_pos, workspot_angle)
    self:KeepWorkspotSeatPostion(local_workspot_pos, workspot_angle)
    Cron.After(self.wait_time_after_standup, function()
        self.log_obj:Record(LogLevel.Trace, "EnableWalkingMetro: Unmount")
        self:SetFreezeMode(true)
        self.metro_obj:Unmount()
        self.event_obj:SetStatus(Def.State.WalkInsideMetro)
        self.is_switching_pose = false
        Cron.After(0.5, function()
            self:SetFreezeMode(false)
        end)
    end)

end

function Core:DisableWalkingMetro()

    if self.is_switching_pose then
        return
    end
    self.is_switching_pose = true

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
                self.is_switching_pose = false
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

function Core:UpdateAvoidanceMove(delta)

    local player = Game.GetPlayer()
    local local_player_pos = Vector4.new(self.event_obj.prev_player_local_pos.x, self.event_obj.prev_player_local_pos.y, 0.5, 1)
    local world_player_pos = self.metro_obj:GetAccurateWorldPosition(local_player_pos)
    local move_speed = 1.5
    local forward_dir = player:GetWorldForward()
    local right_dir = player:GetWorldRight()
    local x,y = world_player_pos.x, world_player_pos.y
    if self.move_forward then
        x = x + forward_dir.x * move_speed * delta
        y = y + forward_dir.y * move_speed * delta
    end
    if self.move_backward then
        x = x - forward_dir.x * move_speed * delta
        y = y - forward_dir.y * move_speed * delta
    end
    if self.move_right then
        x = x + right_dir.x * move_speed * delta
        y = y + right_dir.y * move_speed * delta
    end
    if self.move_left then
        x = x - right_dir.x * move_speed * delta
        y = y - right_dir.y * move_speed * delta
    end
    local new_pos = Vector4.new(x, y, world_player_pos.z, 1)
    local local_player_pos = self.metro_obj:GetAccurateLocalPosition(new_pos)
    if self.metro_obj:IsInMetro(local_player_pos) then
        self.event_obj.prev_player_local_pos = local_player_pos
    else
        new_pos = world_player_pos
    end
    local angle = self.metro_obj.measurement_npc_entity:GetWorldOrientation():ToEulerAngles()
    Game.GetTeleportationFacility():Teleport(player, new_pos, EulerAngles.new(angle.roll, angle.pitch, GetPlayer():GetWorldYaw() + self.move_yaw))
end

return Core