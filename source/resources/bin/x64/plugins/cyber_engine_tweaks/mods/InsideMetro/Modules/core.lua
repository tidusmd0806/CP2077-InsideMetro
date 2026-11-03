local Event = require('Modules/event.lua')
local Metro = require('Modules/metro.lua')
local Config = require('Etc/config.lua')

local Core = {}
Core.__index = Core

function Core:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Core")
    obj.metro_obj = Metro:New()
    obj.event_obj = Event:New(obj.metro_obj)
    obj.config_obj = Config:New()
    -- static --
    obj.event_check_interval = 0.01
    -- dynamic --
    obj.is_locked_apply_action = false
    obj.is_switching_pose = false
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

        if self.event_obj:IsInPouse() then
            return
        end
        local status = self.event_obj:GetStatus()
        if status == Def.State.EnableStand and not self.metro_obj:IsCurrentInvalidStation() then
            if action_name == "ChoiceApply" and action_type == "BUTTON_PRESSED" then
                if self.is_locked_apply_action then
                    return
                end
                self.is_locked_apply_action = true
                self:EnableWalkingMetro()
                Cron.After(5.5, function()
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

-- Restore default camera params, same event a jump sends
function Core:ResetCamera()
    if self.config_obj.standup_camera_reset ~= 1 then
        return
    end
    pcall(function()
        local evt = NewObject('gameSetCameraParamsEvent')
        evt.paramsName = CName.new("Default")
        Game.GetPlayer():QueueEvent(evt)
    end)
end

-- stand up via StopInDevice + Unmount
function Core:EnableWalkingMetro()
    if self.is_switching_pose then
        return
    end
    self.is_switching_pose = true

    self.log_obj:Record(LogLevel.Info, "EnableWalkingMetro")

    local freeze = self.config_obj.standup_freeze == 1
    local eyes = self.config_obj.standup_eyes == 1
    if freeze then
        if eyes then
            GameObjectEffectHelper.StartEffectEvent(Game.GetPlayer(), "eyes_closed_loop", true, worldEffectBlackboard.new())
        end
        self:SetFreezeMode(true)
    end
    if self.config_obj.standup_stop_in_device == 1 then
        Game.GetWorkspotSystem():StopInDevice(Game.GetPlayer())
    end
    local hold = self.config_obj.standup_hold_pos == 1
    local function do_unmount()
        self.log_obj:Record(LogLevel.Trace, "EnableWalkingMetro: Unmount")
        self.metro_obj:Unmount()
        self.event_obj:SetStatus(Def.State.WalkInsideMetro)
        self.is_switching_pose = false
        if hold then
            self.metro_obj:TeleportToStandHold()
            if not freeze then
                Cron.After(0.3, function()
                    self.metro_obj:TeleportToStandHold()
                    self:ResetCamera()
                end)
            end
        end
        if freeze then
            Cron.After(0.5, function()
                if hold then
                    self.metro_obj:TeleportToStandHold()
                end
                self:SetFreezeMode(false)
                self:ResetCamera()
                if eyes then
                    GameObjectEffectHelper.StopEffectEvent(Game.GetPlayer(), "eyes_closed_loop")
                    GameObjectEffectHelper.StartEffectEvent(Game.GetPlayer(), "eyes_opening_05s", true, worldEffectBlackboard.new())
                end
            end)
        end
    end
    if self.config_obj.standup_stop_in_device == 1 and self.config_obj.standup_stop_gap > 0 then
        Cron.After(self.config_obj.standup_stop_gap, do_unmount)
    else
        do_unmount()
    end
end

-- sit down via pose-change fact
function Core:DisableWalkingMetro()
    if self.is_switching_pose then
        return
    end
    self.is_switching_pose = true

    self.log_obj:Record(LogLevel.Info, "DisableWalkingMetro")
    -- suppress the stand choice until the scene resets the stand fact
    self.event_obj.is_stand_choice_dismissed = true

    local freeze = self.config_obj.sit_fact_freeze == 1
    if freeze then
        self:SetFreezeMode(true)
    end
    local fact_done = false
    local function finish()
        if fact_done then
            return
        end
        fact_done = true
        self.event_obj:SetStatus(Def.State.SitInsideMetro)
        Cron.After(self.config_obj.sit_fact_delay, function()
            Game.GetQuestsSystem():SetFactStr(self.config_obj.sit_fact_name, 1)
            self.log_obj:Record(LogLevel.Trace, "DisableWalkingMetro: fact set")
            self.is_switching_pose = false
            if freeze then
                Cron.After(1.0, function()
                    self:SetFreezeMode(false)
                end)
            end
        end)
    end
    Cron.After(0.01, function()
        self.metro_obj:Mount()
        Cron.Every(0.01, {tick = 1}, function(timer)
            if Game.GetPlayer():GetMountedVehicle() == nil then
                return
            end
            Cron.Halt(timer)
            finish()
        end)
    end)
    -- safety: never leave the player frozen if mount detection fails
    Cron.After(5.0, function()
        if not fact_done then
            self.log_obj:Record(LogLevel.Warning, "DisableWalkingMetro: mount timeout")
            finish()
        end
    end)
end

return Core
