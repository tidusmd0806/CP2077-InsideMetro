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
    obj.keep_seat_timer = nil
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
                if self.event_obj.hud_obj.selected_choice_index ~= Def.ChoiceText.Exit or self.is_locked_apply_action then
                    consumer:Consume()
                end
                if self.event_obj.next_stock_station_num ~= 0 then
                    Game.GetQuestsSystem():SetFact("ue_metro_next_station", self.event_obj.next_stock_station_num)
                    self.event_obj.next_stock_station_num = 0
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
        elseif status == Def.State.SitInsideMetro and not self.metro_obj:IsCurrentInvalidStation() then
            if action_name == "UETExit" and action_type == "BUTTON_PRESSED" then
                if self.event_obj.next_stock_station_num ~= 0 then
                    Game.GetQuestsSystem():SetFact("ue_metro_next_station", self.event_obj.next_stock_station_num)
                    self.event_obj.next_stock_station_num = 0
                end
            end
        end
    end)
end

function Core:SetFreezeMode(is_freeze)
    if is_freeze then
        Game.GetTimeSystem():SetTimeDilation(CName.new("pause"), 0.01)
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

    self.event_obj.next_stock_station_num = 0

    self.log_obj:Record(LogLevel.Info, "EnableWalkingMetro")

    -- While the metro entity transform is stalling (typically right after
    -- departure), positions computed from it are unreliable. Defer the actual
    -- stand-up until the transform catches up instead of blocking the menu.
    if self.metro_obj:IsTransformLagging() then
        self.log_obj:Record(LogLevel.Info, "EnableWalkingMetro: transform lagging, deferring stand-up")
        Cron.Every(0.1, {tick = 0}, function(timer)
            timer.tick = timer.tick + 1
            if self.metro_obj:IsTransformLagging() and timer.tick < 50 then
                return
            end
            if self.metro_obj:IsTransformLagging() then
                self.log_obj:Record(LogLevel.Warning, "EnableWalkingMetro: transform still lagging after 5s, standing up anyway")
            end
            Cron.Halt(timer)
            self:StartStandingUp()
        end)
        return
    end

    self:StartStandingUp()
end

function Core:StartStandingUp()
    -- Re-acquire the metro entity right before computing positions so the
    -- transform used is guaranteed fresh (the player is mounted at this point).
    self.metro_obj:SetEntity()
    local local_workspot_pos = self.metro_obj:GetPlayerSeatPositionRaw()
    local workspot_angle = self.metro_obj:GetSeatAngle()
    local world_pos = self.metro_obj:GetAccurateWorldPosition(local_workspot_pos)
    self.player_obj:PlayPose(self.stand_up_anim, world_pos, workspot_angle)
    self:KeepWorkspotSeatPostion(local_workspot_pos)
    self:StartPoseDiagnostics(local_workspot_pos)
    Cron.After(self.wait_time_after_standup, function()
        self.log_obj:Record(LogLevel.Trace, "EnableWalkingMetro: Unmount")
        self:LogPoseDiagSample("pre-unmount", local_workspot_pos)
        self:SetFreezeMode(true)
        Cron.After(0.5, function()
            self.metro_obj:Unmount()
            self.event_obj:SetStatus(Def.State.WalkInsideMetro)
            self.is_switching_pose = false
            Cron.After(0.5, function()
                self:SetFreezeMode(false)
            end)
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
    Cron.After(0.01, function()
        self.metro_obj:Mount()
        Cron.Every(0.01, {tick = 1}, function(timer)
            if Game.GetPlayer():GetMountedVehicle() == nil then
                self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: Player is in vehicle")
                return
            end

            self.event_obj:SetStatus(Def.State.SitInsideMetro)

            local seat_local_pos = self.metro_obj:GetPlayerSeatPosition()
            local workspot_pos = self.metro_obj:GetAccurateWorldPosition(seat_local_pos)
            local workspot_angle = self.metro_obj:GetSeatAngle()
            local player_pos = Game.GetPlayer():GetWorldPosition()
            self.log_obj:Record(LogLevel.Info, string.format(
                "DIAG[sit-trigger] speed=%.2f seat_local=(%.2f,%.2f,%.2f) workspot_world=(%.2f,%.2f,%.2f) player=(%.2f,%.2f,%.2f)",
                self.metro_obj:GetSpeed(),
                seat_local_pos.x, seat_local_pos.y, seat_local_pos.z,
                workspot_pos.x, workspot_pos.y, workspot_pos.z,
                player_pos.x, player_pos.y, player_pos.z))
            self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: PlayPose")
            self.player_obj:PlayPose(self.sit_down_anim, workspot_pos, workspot_angle)
            -- Keep the workspot following the moving metro so the seat position
            -- does not drift while the train is running.
            self:KeepWorkspotSeatPostion(seat_local_pos)
            Cron.After(0.5, function()
                self:SetFreezeMode(false)
                self.is_switching_pose = false
            end)

            Cron.Halt(timer)
        end)
    end)
end

-- Follows the metro every tick: re-computes both position and orientation
-- from the current metro transform (the train yaw changes constantly on curves).
function Core:KeepWorkspotSeatPostion(local_pos)
    -- Only one follower can be active at a time.
    if self.keep_seat_timer ~= nil then
        Cron.Halt(self.keep_seat_timer)
        self.keep_seat_timer = nil
    end
    self.keep_seat_timer = Cron.Every(0.01, {tick = 1}, function(timer)
        local workspot_entity = self.player_obj:GetWorkspotEntity()
        if workspot_entity == nil then
            self.log_obj:Record(LogLevel.Trace, "KeepWorkspotSeatPostion: workspot_entity is nil")
            return
        end
        timer.tick = timer.tick + 1
        -- Metro entity is gone (player got off / session ended): stop following.
        if self.metro_obj.entity == nil then
            self.log_obj:Record(LogLevel.Trace, "KeepWorkspotSeatPostion: metro entity is nil")
            self.player_obj:DeleteWorkspot()
            Cron.Halt(timer)
            self.keep_seat_timer = nil
            return
        end
        local base_pos = self.metro_obj:GetAccurateWorldPosition(local_pos)
        if base_pos == nil then
            self.log_obj:Record(LogLevel.Error, "KeepWorkspotSeatPostion: base_pos is nil")
            Cron.Halt(timer)
            self.keep_seat_timer = nil
            return
        end
        local world_pos = self.metro_obj:ExtrapolateWorldPosition(base_pos)
        local angle = self.metro_obj:GetSeatAngle()
        if world_pos == nil or angle == nil then
            self.log_obj:Record(LogLevel.Error, "KeepWorkspotSeatPostion: pos or angle is nil")
            Cron.Halt(timer)
            self.keep_seat_timer = nil
            return
        end

        Game.GetTeleportationFacility():Teleport(workspot_entity, world_pos, angle)
        if timer.tick % 100 == 0 then
            local metro_pos = self.metro_obj:GetWorldPosition()
            if metro_pos ~= nil then
                self.log_obj:Record(LogLevel.Info, string.format(
                    "DIAG[follow t=%d] target=(%.2f,%.2f,%.2f) metro=(%.2f,%.2f,%.2f) speed=%.1f lead=%.3f",
                    timer.tick, world_pos.x, world_pos.y, world_pos.z,
                    metro_pos.x, metro_pos.y, metro_pos.z,
                    self.metro_obj:GetSpeed(), self.metro_obj.workspot_lead_time))
            end
        end
        if not self.metro_obj:IsMountedPlayer() then
            self.log_obj:Record(LogLevel.Trace, "DeleteWorkspot")
            self.player_obj:DeleteWorkspot()
            Cron.Halt(timer)
            self.keep_seat_timer = nil
            return
        end
    end)
end

-- Diagnostics: one sample of the standing pipeline (player position in metro
-- space vs the recorded seat). drift should stay near zero while the player is
-- attached to the train; a growing drift means the metro entity transform
-- moves differently from the player/train attachment.
function Core:LogPoseDiagSample(tag, seat_local_pos)
    local metro = self.metro_obj
    local player = Game.GetPlayer()
    if player == nil or metro.player_seat_position == nil then
        self.log_obj:Record(LogLevel.Info, "DIAG[" .. tag .. "] player or seat not ready")
        return
    end
    local player_pos = player:GetWorldPosition()
    local player_local = metro:ChangeWorldPosToLocal(player_pos)
    local metro_pos = metro:GetWorldPosition()
    if player_pos == nil or player_local == nil or metro_pos == nil then
        self.log_obj:Record(LogLevel.Info, "DIAG[" .. tag .. "] nil positions")
        return
    end
    local seat = metro.player_seat_position
    local ws_str = "nil"
    local ws = self.player_obj:GetWorkspotEntity()
    if ws ~= nil then
        local ok, ws_pos = pcall(function(e)
            return e:GetWorldPosition()
        end, ws)
        if ok and ws_pos ~= nil then
            ws_str = string.format("(%.2f,%.2f,%.2f)", ws_pos.x, ws_pos.y, ws_pos.z)
        else
            ws_str = "stale"
        end
    end
    self.log_obj:Record(LogLevel.Info, string.format(
        "DIAG[%s] speed=%.2f metro=(%.2f,%.2f,%.2f) player=(%.2f,%.2f,%.2f) player_local=(%.2f,%.2f,%.2f) seat_local=(%.2f,%.2f,%.2f) drift=(%+.2f,%+.2f,%+.2f) workspot=%s",
        tag, metro:GetSpeed(),
        metro_pos.x, metro_pos.y, metro_pos.z,
        player_pos.x, player_pos.y, player_pos.z,
        player_local.x, player_local.y, player_local.z,
        seat.x, seat.y, seat.z,
        player_local.x - seat.x, player_local.y - seat.y, player_local.z - seat.z,
        ws_str))
end

-- Sample the whole standing pipeline for ~5 seconds after the stand-up starts.
function Core:StartPoseDiagnostics(seat_local_pos)
    self:LogPoseDiagSample("stand-trigger", seat_local_pos)
    Cron.Every(0.1, {tick = 0}, function(timer)
        timer.tick = timer.tick + 1
        self:LogPoseDiagSample(string.format("stand-%02d", timer.tick), seat_local_pos)
        if timer.tick >= 50 then
            Cron.Halt(timer)
        end
    end)
end

return Core